import Foundation
import SwiftUI
import Combine

enum ModalSheetTab: String, CaseIterable {
    case leaderboard = "Leaderboard"
    case analytics = "Analytics"
}

final class GameEngine: ObservableObject {
    @Published var arena: [[Int]]
    @Published var gridX: Int = 3
    @Published var gridY: Int = 2
    @Published var currentShape: [[Int]] = []
    @Published var currentShapeIndex: Int = 0
    @Published var currentRotation: Int = 0

    @Published var nextShapeIndex: Int = 0
    @Published var score: Int = 0 {
        didSet {
            if score > highscore {
                highscore = score
            }
        }
    }
    @Published var highscore: Int = 0
    @Published var linesCleared: Int = 0
    @Published var formattedRunTime: String = "00:00"
    @Published var isDead: Bool = false
    @Published var isPaused: Bool = false
    @Published var activeModalTab: ModalSheetTab = .leaderboard
    @Published var showHistory: Bool = false {
        didSet {
            if showHistory && !isDead && !isPaused {
                autoPause()
            }
        }
    }
    @Published private(set) var isStackInDangerZone: Bool = false

    // Internal un-published time counter to prevent 60Hz SwiftUI invalidations
    var currentRunTime: Double = 0
    private var lastFormattedSecond: Int = -1
    private var totalPlayTimeAccumulator: Double = 0
    private var periodicSaveCounter: Int = 0

    // Discrete gravity & lock timers
    private var gravityCounter: Int = 0
    private var lockTimer: Int = 0
    private var lockResets: Int = 0
    private let maxLockResets: Int = 15
    private let standardLockDelay: Int = 27 // 27 frames = 450ms (matches original Stacker LOCK_DELAY)
    private var isSoftDropping: Bool = false

    // Symmetrical, perfectly matched movement speeds
    private var isLeftHeld: Bool = false
    private var isRightHeld: Bool = false
    private var leftHoldTimer: Int = 0
    private var rightHoldTimer: Int = 0
    private let dasDelay: Int = 5   // ~80ms hold threshold
    private let arrSpeed: Int = 4   // ~66ms repeat interval (matches original HORIZONTAL_MOVEMENT_INTERVAL: 76ms)
    private let softDropSpeed: Int = 3 // ~50ms per row (matches original DROP_KEY_INTERVAL: 44ms)
    private let normalGravitySpeed: Int = 21 // ~350ms per row (matches original DROP_INTERVAL: 350ms)

    private let bag = Bag()
    private var timer: Timer?

    init() {
        self.arena = Array(repeating: Array(repeating: 0, count: GameConfig.columns), count: GameConfig.rows)
        self.highscore = ScoreHistoryManager.shared.highestScore

        if let saved = StateManager.shared.loadState(), !saved.isDead {
            self.arena = saved.arenaMatrix
            self.gridX = saved.gridX
            self.gridY = saved.gridY
            self.currentShapeIndex = saved.currentShapeIndex
            self.currentRotation = saved.currentRotation
            let piece = TetrominoType(rawValue: saved.currentShapeIndex) ?? .t
            self.currentShape = piece.allRotationStates[saved.currentRotation % 4]
            self.nextShapeIndex = saved.nextShapeIndex
            self.bag.setBag(saved.bag)
            self.score = saved.score
            self.highscore = max(saved.highscore, ScoreHistoryManager.shared.highestScore)
            self.linesCleared = saved.linesCleared
            self.currentRunTime = saved.currentRunTime
            self.isDead = false
            self.isPaused = true
            updateFormattedRunTime()
            updateDangerZoneStatus()
        } else {
            startNewGame()
        }
    }

    func updateFormattedRunTime() {
        lastFormattedSecond = Int(currentRunTime)
        formattedRunTime = formatClockTime(currentRunTime)
    }

    func updateDangerZoneStatus() {
        for r in 0...6 {
            if arena[r].contains(where: { $0 > 0 }) {
                isStackInDangerZone = true
                return
            }
        }
        isStackInDangerZone = false
    }

    func startNewGame() {
        flushActiveTime(persist: true)
        arena = Array(repeating: Array(repeating: 0, count: GameConfig.columns), count: GameConfig.rows)
        score = 0
        linesCleared = 0
        currentRunTime = 0
        updateFormattedRunTime()
        isDead = false
        isPaused = false
        isSoftDropping = false
        isStackInDangerZone = false
        isLeftHeld = false
        isRightHeld = false
        leftHoldTimer = 0
        rightHoldTimer = 0
        gravityCounter = 0
        lockTimer = 0
        lockResets = 0

        currentShapeIndex = bag.grabIndex()
        nextShapeIndex = bag.grabIndex()

        spawnPiece(shapeIndex: currentShapeIndex)
        saveCurrentState()
        startLoop()
    }

    private func spawnPiece(shapeIndex: Int) {
        guard let pieceType = TetrominoType(rawValue: shapeIndex) else { return }
        currentShapeIndex = shapeIndex
        currentRotation = 0
        currentShape = pieceType.allRotationStates[0]

        switch pieceType {
        case .o:
            gridX = 4
            gridY = 2
        case .i:
            gridX = 3
            gridY = 0
        case .l, .j:
            gridX = 3
            gridY = 1
        default:
            gridX = 3
            gridY = 2
        }

        gravityCounter = isSoftDropping ? (softDropSpeed - 1) : 0
        lockTimer = 0
        lockResets = 0

        if !canPlace(shape: currentShape, atX: gridX, atY: gridY) {
            die()
        }
    }

    func startLoop() {
        guard !isPaused && !isDead else { return }
        if timer != nil { return }
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    func stopLoop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Game Loop (60 FPS)
    func tick() {
        guard !isPaused && !isDead else { return }

        // ONLY counts when actively playing the game
        let delta = 1.0 / 60.0
        currentRunTime += delta
        totalPlayTimeAccumulator += delta

        // Only notify SwiftUI once per second when formatted string changes (avoids 60Hz invalidation storms)
        let currentSec = Int(currentRunTime)
        if currentSec != lastFormattedSecond {
            lastFormattedSecond = currentSec
            formattedRunTime = formatClockTime(currentRunTime)
        }

        if totalPlayTimeAccumulator >= 1.0 {
            ScoreHistoryManager.shared.addPlayTime(totalPlayTimeAccumulator, persistImmediately: false)
            totalPlayTimeAccumulator = 0
        }
        if isStackInDangerZone {
            ScoreHistoryManager.shared.addDangerZoneTime(delta)
        }

        // Periodic disk save every 30 seconds of continuous play to avoid SSD wear
        periodicSaveCounter += 1
        if periodicSaveCounter >= 1800 {
            periodicSaveCounter = 0
            ScoreHistoryManager.shared.save()
        }

        // 1. Smooth horizontal movement when holding keys
        handleHolding()

        // 2. Discrete Gravity & Fall
        let canFall = canPlace(shape: currentShape, atX: gridX, atY: gridY + 1)

        if canFall {
            lockTimer = 0
            gravityCounter += 1
            let dropInterval = isSoftDropping ? softDropSpeed : normalGravitySpeed

            if gravityCounter >= dropInterval {
                gravityCounter = 0
                gridY += 1
                if isSoftDropping {
                    score += 1
                    ScoreHistoryManager.shared.recordSoftDrop()
                }
            }
        } else {
            // Block resting on floor or on top of another block
            if isSoftDropping {
                // When actively soft-dropping with Down/S, lock immediately upon contact!
                // Zero delay, zero pause!
                lockPiece()
            } else {
                // Natural gravity lock delay gives window to slide/rotate
                lockTimer += 1
                if lockTimer >= standardLockDelay {
                    lockPiece()
                }
            }
        }
    }

    private func lockPiece() {
        guard !isDead && !isPaused else { return }
        mergeCurrentPiece()
        score += 10
        lockTimer = 0
        gravityCounter = 0
        lockResets = 0
    }

    private func flushActiveTime(persist: Bool = false) {
        if totalPlayTimeAccumulator > 0 {
            ScoreHistoryManager.shared.addPlayTime(totalPlayTimeAccumulator, persistImmediately: persist)
            totalPlayTimeAccumulator = 0
        } else if persist {
            ScoreHistoryManager.shared.save()
        }
    }

    // Reset lock delay on successful movement or rotation
    private func onPieceMovedOrRotated() {
        if !canPlace(shape: currentShape, atX: gridX, atY: gridY + 1) {
            if lockResets < maxLockResets {
                lockTimer = 0
                lockResets += 1
            }
        }
    }

    // MARK: - DAS / ARR Key Holding
    private func handleHolding() {
        if isLeftHeld && !isRightHeld {
            leftHoldTimer += 1
            if leftHoldTimer >= dasDelay && (leftHoldTimer - dasDelay) % arrSpeed == 0 {
                moveLeft()
            }
        } else if isRightHeld && !isLeftHeld {
            rightHoldTimer += 1
            if rightHoldTimer >= dasDelay && (rightHoldTimer - dasDelay) % arrSpeed == 0 {
                moveRight()
            }
        }
    }

    func setLeftHeld(_ held: Bool) {
        if held && !isLeftHeld {
            moveLeft()
            leftHoldTimer = 0
        }
        isLeftHeld = held
        if !held {
            leftHoldTimer = 0
        }
    }

    func setRightHeld(_ held: Bool) {
        if held && !isRightHeld {
            moveRight()
            rightHoldTimer = 0
        }
        isRightHeld = held
        if !held {
            rightHoldTimer = 0
        }
    }

    func moveLeft() {
        guard !isDead && !isPaused else { return }
        if canPlace(shape: currentShape, atX: gridX - 1, atY: gridY) {
            gridX -= 1
            onPieceMovedOrRotated()
        }
    }

    func moveRight() {
        guard !isDead && !isPaused else { return }
        if canPlace(shape: currentShape, atX: gridX + 1, atY: gridY) {
            gridX += 1
            onPieceMovedOrRotated()
        }
    }

    func setSoftDropping(_ active: Bool) {
        isSoftDropping = active
        // If already resting on bottom/stack and user presses Down/S, lock immediately!
        if active && !canPlace(shape: currentShape, atX: gridX, atY: gridY + 1) {
            lockPiece()
        }
    }

    // MARK: - Hard Drop (Spacebar)
    func hardDrop() {
        guard !isDead && !isPaused else { return }

        var targetY = gridY
        while canPlace(shape: currentShape, atX: gridX, atY: targetY + 1) {
            targetY += 1
        }

        let rowsDropped = targetY - gridY
        if rowsDropped > 0 {
            score += rowsDropped * 2
        }
        ScoreHistoryManager.shared.recordHardDrop(rows: rowsDropped)

        gridY = targetY
        lockPiece()
    }

    // MARK: - Linear Rotation with Wall Kicks
    func rotate(dir: Int = 1) {
        guard !isDead && !isPaused else { return }
        guard let piece = TetrominoType(rawValue: currentShapeIndex) else { return }

        let nextRot = (currentRotation + dir + 4) % 4
        let testShape = piece.allRotationStates[nextRot]

        let kicks = [0, 1, -1, 2, -2, 3, -3]

        for offset in kicks {
            let testX = gridX + offset
            if canPlace(shape: testShape, atX: testX, atY: gridY) {
                gridX = testX
                currentRotation = nextRot
                currentShape = testShape
                onPieceMovedOrRotated()
                return
            }
        }
    }

    // MARK: - Pause Controls
    func togglePause() {
        guard !isDead else { return }
        flushActiveTime(persist: true)
        isPaused.toggle()
        if isPaused {
            stopLoop()
            saveCurrentState()
        } else {
            startLoop()
        }
    }

    func autoPause() {
        if !isDead && !isPaused {
            flushActiveTime(persist: true)
            isPaused = true
            stopLoop()
            saveCurrentState()
        }
    }

    func unpause() {
        guard !isDead && isPaused else { return }
        flushActiveTime(persist: true)
        isPaused = false
        startLoop()
    }

    // MARK: - Discrete Collision & Boundary Check
    func canPlace(shape: [[Int]], atX testX: Int, atY testY: Int) -> Bool {
        for r in 0..<shape.count {
            for c in 0..<shape[r].count {
                if shape[r][c] != 0 {
                    let col = testX + c
                    let row = testY + r

                    if col < 0 || col >= GameConfig.columns {
                        return false
                    }
                    if row >= GameConfig.rows {
                        return false
                    }
                    if row >= 0 && arena[row][col] != 0 {
                        return false
                    }
                }
            }
        }
        return true
    }

    // MARK: - Merging & Immediate Line Clearing
    private func mergeCurrentPiece() {
        guard let pieceType = TetrominoType(rawValue: currentShapeIndex) else { return }
        let colorIdx = pieceType.colorIndex

        for r in 0..<currentShape.count {
            for c in 0..<currentShape[r].count {
                if currentShape[r][c] != 0 {
                    let boardRow = gridY + r
                    let boardCol = gridX + c

                    if boardRow >= 0 && boardRow < GameConfig.rows && boardCol >= 0 && boardCol < GameConfig.columns {
                        arena[boardRow][boardCol] = colorIdx
                    }
                }
            }
        }

        ScoreHistoryManager.shared.recordPiecePlaced(shapeIndex: currentShapeIndex)

        // Check death condition: any settled block in rows 0..<4
        var hitCeiling = false
        for r in 0..<GameConfig.deathLimitRow {
            if arena[r].contains(where: { $0 > 0 }) {
                hitCeiling = true
                break
            }
        }

        if hitCeiling {
            die()
            return
        }

        // Immediately clear completed lines
        var cleared = 0
        var lineClearScore = 0.0

        for r in 0..<GameConfig.rows {
            if arena[r].allSatisfy({ $0 > 0 }) {
                arena.remove(at: r)
                arena.insert(Array(repeating: 0, count: GameConfig.columns), at: 0)

                lineClearScore = (lineClearScore * 1.5) + 75.0
                cleared += 1
                linesCleared += 1
            }
        }

        if cleared > 0 {
            score += Int(round(lineClearScore))
            ScoreHistoryManager.shared.recordLineClears(count: cleared)
        }

        updateDangerZoneStatus()

        currentShapeIndex = nextShapeIndex
        nextShapeIndex = bag.grabIndex()
        spawnPiece(shapeIndex: currentShapeIndex)

        saveCurrentState()
    }

    private func die() {
        isDead = true
        stopLoop()
        flushActiveTime(persist: true)
        ScoreHistoryManager.shared.recordGameFinished(score: score, lines: linesCleared, duration: currentRunTime)
        StateManager.shared.clearState()
    }

    // MARK: - State Persistence
    func saveCurrentState() {
        guard !isDead else { return }
        flushActiveTime(persist: true)
        let state = SavedGameState(
            arenaMatrix: arena,
            gridX: gridX,
            gridY: gridY,
            currentShapeIndex: currentShapeIndex,
            currentRotation: currentRotation,
            nextShapeIndex: nextShapeIndex,
            bag: bag.getRemainingBag(),
            score: score,
            highscore: highscore,
            linesCleared: linesCleared,
            currentRunTime: currentRunTime,
            isDead: isDead,
            isPaused: isPaused
        )
        StateManager.shared.saveState(state)
    }

    // MARK: - Colors & Helpers
    var currentColor: Color {
        TetrominoType(rawValue: currentShapeIndex)?.color ?? .white
    }

    var nextColor: Color {
        TetrominoType(rawValue: nextShapeIndex)?.color ?? .white
    }

    var nextShapeMatrix: [[Int]] {
        TetrominoType(rawValue: nextShapeIndex)?.defaultMatrix ?? []
    }
}
