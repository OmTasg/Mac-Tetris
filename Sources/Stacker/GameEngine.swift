import Foundation
import SwiftUI
import Combine

final class GameEngine: ObservableObject {
    @Published var arena: [[Int]]
    @Published var gridX: Int = 3
    @Published var gridY: Int = 1
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

    // Smooth line clear collapse animation
    @Published var lineClearOffset: Double = 0
    @Published var lineClearBreakRow: Int? = nil
    private var lineClearYV: Double = 0

    // Discrete gravity & lock timers
    private var gravityCounter: Int = 0
    private var lockTimer: Int = 0
    private var isSoftDropping: Bool = false

    // DAS (Delayed Auto Shift) & ARR (Auto Repeat Rate)
    private var isLeftHeld: Bool = false
    private var isRightHeld: Bool = false
    private var leftHoldTimer: Int = 0
    private var rightHoldTimer: Int = 0
    private let dasDelay: Int = 10  // ~160ms delay before repeat
    private let arrSpeed: Int = 2   // repeat every 2 frames (~33ms)

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
            self.isPaused = true // Open paused so player can prepare
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
        lineClearOffset = 0
        lineClearBreakRow = nil
        lineClearYV = 0

        currentShapeIndex = bag.grabIndex()
        nextShapeIndex = bag.grabIndex()

        spawnPiece(shapeIndex: currentShapeIndex)
        saveCurrentState()
    }

    private func spawnPiece(shapeIndex: Int) {
        guard let pieceType = TetrominoType(rawValue: shapeIndex) else { return }
        currentShapeIndex = shapeIndex
        currentRotation = 0
        currentShape = pieceType.allRotationStates[0]

        let shapeWidth = currentShape[0].count
        gridX = (GameConfig.columns - shapeWidth) / 2
        gridY = 1
        gravityCounter = 0
        lockTimer = 0

        // If spawn position immediately collides, game over
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

        // 1. Handle Held Left / Right Movement (DAS / ARR)
        handleHolding()

        // 2. Line clear smooth collapse
        if lineClearOffset < 0 {
            lineClearOffset = min(0, lineClearOffset + lineClearYV)
            if lineClearOffset == 0 {
                lineClearBreakRow = nil
                lineClearYV = 0
            }
        }

        // 3. Discrete Gravity & Fall
        let canFall = canPlace(shape: currentShape, atX: gridX, atY: gridY + 1)

        if canFall {
            lockTimer = 0
            gravityCounter += 1
            // Soft drop falls every 2 frames (~30 rows/sec); normal gravity falls every 25 frames (~2.4 rows/sec)
            let dropInterval = isSoftDropping ? 2 : 25

            if gravityCounter >= dropInterval {
                gravityCounter = 0
                gridY += 1
                if isSoftDropping {
                    score += 1
                }
            }
        } else {
            // Block is resting on the ground or on top of another block
            lockTimer += 1
            // 25 frames lock delay (~0.4s), or instant if soft dropping
            if lockTimer >= 25 || (isSoftDropping && lockTimer >= 5) {
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
            moveLeft() // Immediate response on initial tap
            leftHoldTimer = 0
        }
        isLeftHeld = held
        if !held {
            leftHoldTimer = 0
        }
    }

    func setRightHeld(_ held: Bool) {
        if held && !isRightHeld {
            moveRight() // Immediate response on initial tap
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

        // Standard wall kicks to test: in-place (0), kick right (+1), kick left (-1), kick right (+2), kick left (-2)
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

                    // MUST be strictly within 0..<10
                    if col < 0 || col >= GameConfig.columns {
                        return false
                    }

                    // MUST be strictly < 18
                    if row >= GameConfig.rows {
                        return false
                    }

                    // MUST NOT collide with placed blocks
                    if row >= 0 && arena[row][col] != 0 {
                        return false
                    }
                }
            }
        }
        return true
    }

    // MARK: - Merging & Line Clearing
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

        // Clear completed lines using Stacker's exact formula
        var cleared = 0
        var lineClearScore = 0.0

        for r in 0..<GameConfig.rows {
            if arena[r].allSatisfy({ $0 > 0 }) {
                arena.remove(at: r)
                arena.insert(Array(repeating: 0, count: GameConfig.columns), at: 0)

                lineClearScore = (lineClearScore * 1.5) + 75.0
                cleared += 1
                linesCleared += 1

                // Visual collapse effect
                lineClearOffset -= GameConfig.cellSize
                lineClearBreakRow = r + 1
                if lineClearYV == 0 {
                    lineClearYV += 2.0
                } else {
                    lineClearYV += 1.0
                }
            }
        }

        if cleared > 0 {
            score += Int(round(lineClearScore))
        }

        // Spawn next piece
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
