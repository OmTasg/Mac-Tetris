import Foundation
import SwiftUI
import Combine

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
    @Published var isDead: Bool = false
    @Published var isPaused: Bool = false
    @Published var showHistory: Bool = false

    // Discrete gravity & lock timers
    private var gravityCounter: Int = 0
    private var lockTimer: Int = 0
    private var isSoftDropping: Bool = false

    // Perfectly tuned DAS (Delayed Auto Shift) & ARR (Auto Repeat Rate)
    private var isLeftHeld: Bool = false
    private var isRightHeld: Bool = false
    private var leftHoldTimer: Int = 0
    private var rightHoldTimer: Int = 0
    private let dasDelay: Int = 5   // ~80ms quick transition into hold
    private let arrSpeed: Int = 3   // 1 column every 3 frames = 20 cols/sec (smooth and controllable)

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
            self.isDead = false
            self.isPaused = true
        } else {
            startNewGame()
        }

        startLoop()
    }

    func startNewGame() {
        arena = Array(repeating: Array(repeating: 0, count: GameConfig.columns), count: GameConfig.rows)
        score = 0
        linesCleared = 0
        isDead = false
        isPaused = false
        isSoftDropping = false
        isLeftHeld = false
        isRightHeld = false
        leftHoldTimer = 0
        rightHoldTimer = 0
        gravityCounter = 0
        lockTimer = 0

        currentShapeIndex = bag.grabIndex()
        nextShapeIndex = bag.grabIndex()

        spawnPiece(shapeIndex: currentShapeIndex)
        saveCurrentState()
    }

    private func spawnPiece(shapeIndex: Int) {
        guard let pieceType = TetrominoType(rawValue: shapeIndex) else { return }
        currentShapeIndex = shapeIndex
        currentRotation = 0 // Always default orientation (state 0)
        currentShape = pieceType.allRotationStates[0]

        // Default canonical spawn positions (facing up / straight up above the red line)
        switch pieceType {
        case .o:
            gridX = 4
            gridY = 2
        case .i:
            // Vertical straight-up piece
            gridX = 3
            gridY = 0 // Spans rows 0, 1, 2, 3 ending right at red line
        case .l, .j:
            // Upright L and backwards-L pieces
            gridX = 3
            gridY = 1 // Spans rows 1, 2, 3 ending right at red line
        default:
            gridX = 3
            gridY = 2
        }

        gravityCounter = 0
        lockTimer = 0

        if !canPlace(shape: currentShape, atX: gridX, atY: gridY) {
            die()
        }
    }

    func startLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopLoop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Game Loop (60 FPS)
    func tick() {
        guard !isPaused && !isDead else { return }

        // 1. Smooth, controllable horizontal movement
        handleHolding()

        // 2. Discrete Gravity & Fall
        let canFall = canPlace(shape: currentShape, atX: gridX, atY: gridY + 1)

        if canFall {
            lockTimer = 0
            gravityCounter += 1
            let dropInterval = isSoftDropping ? 5 : 25

            if gravityCounter >= dropInterval {
                gravityCounter = 0
                gridY += 1
                if isSoftDropping {
                    score += 1
                }
            }
        } else {
            // Block resting on floor or on top of another block
            lockTimer += 1
            if lockTimer >= 22 || (isSoftDropping && lockTimer >= 6) {
                mergeCurrentPiece()
                score += 10
                lockTimer = 0
                gravityCounter = 0
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
        }
    }

    func moveRight() {
        guard !isDead && !isPaused else { return }
        if canPlace(shape: currentShape, atX: gridX + 1, atY: gridY) {
            gridX += 1
        }
    }

    func setSoftDropping(_ active: Bool) {
        isSoftDropping = active
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

        gridY = targetY
        mergeCurrentPiece()
        score += 10
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
                return
            }
        }
    }

    // MARK: - Pause Controls
    func togglePause() {
        guard !isDead else { return }
        isPaused.toggle()
        if isPaused {
            saveCurrentState()
        }
    }

    func autoPause() {
        if !isDead && !isPaused {
            isPaused = true
            saveCurrentState()
        }
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

    // MARK: - Merging & Immediate Line Clearing (No Animation)
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

        // Immediately clear completed lines (No delay or animation)
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
        }

        // Spawn next piece always in default rotation and position
        currentShapeIndex = nextShapeIndex
        nextShapeIndex = bag.grabIndex()
        spawnPiece(shapeIndex: currentShapeIndex)

        saveCurrentState()
    }

    private func die() {
        isDead = true
        ScoreHistoryManager.shared.record(score: score, lines: linesCleared)
        StateManager.shared.clearState()
    }

    // MARK: - State Persistence
    func saveCurrentState() {
        guard !isDead else { return }
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
