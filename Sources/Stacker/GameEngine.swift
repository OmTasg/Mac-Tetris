import Foundation
import SwiftUI
import Combine

final class GameEngine: ObservableObject {
    @Published var arena: [[Int]]
    @Published var gridX: Int = 3
    @Published var currentY: Double = 1.0
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
    @Published var isSoftDropping: Bool = false

    // Smooth line clear animation
    @Published var lineClearOffset: Double = 0
    @Published var lineClearBreakRow: Int? = nil
    private var lineClearYV: Double = 0

    private let bag = Bag()
    private var timer: Timer?

    init() {
        self.arena = Array(repeating: Array(repeating: 0, count: GameConfig.columns), count: GameConfig.rows)
        self.highscore = ScoreHistoryManager.shared.highestScore

        if let saved = StateManager.shared.loadState(), !saved.isDead {
            // Restore from saved state
            self.arena = saved.arenaMatrix
            self.gridX = saved.gridX
            self.currentY = saved.currentY
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
            self.isPaused = true // Open paused so player is ready
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

        // Spawn centered horizontally on the grid
        let shapeWidth = currentShape[0].count
        gridX = (GameConfig.columns - shapeWidth) / 2
        // Spawn above red line
        currentY = 1.0

        // If spawn position immediately collides, game over
        if !isValidPosition(shape: currentShape, atX: gridX, atY: currentY) {
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

    // MARK: - Game Loop
    func tick() {
        guard !isPaused && !isDead else { return }

        // Line clear smooth collapse
        if lineClearOffset < 0 {
            lineClearOffset = min(0, lineClearOffset + lineClearYV)
            if lineClearOffset == 0 {
                lineClearBreakRow = nil
                lineClearYV = 0
            }
        }

        // Determine fall speed
        let speed = isSoftDropping ? GameConfig.softDropSpeed : GameConfig.normalFallSpeed
        let nextY = currentY + speed

        if isValidPosition(shape: currentShape, atX: gridX, atY: nextY) {
            if isSoftDropping {
                let oldRow = Int(floor(currentY))
                let newRow = Int(floor(nextY))
                if newRow > oldRow {
                    score += 1
                }
            }
            currentY = nextY
        } else {
            // Reached ground / resting position
            currentY = Double(Int(floor(currentY)))
            mergeCurrentPiece()
            score += 10
        }
    }

    // MARK: - Discrete Grid Movement
    func moveLeft() {
        guard !isDead && !isPaused else { return }
        if isValidPosition(shape: currentShape, atX: gridX - 1, atY: currentY) {
            gridX -= 1
        }
    }

    func moveRight() {
        guard !isDead && !isPaused else { return }
        if isValidPosition(shape: currentShape, atX: gridX + 1, atY: currentY) {
            gridX += 1
        }
    }

    func setSoftDropping(_ active: Bool) {
        isSoftDropping = active
    }

    func hardDrop() {
        guard !isDead && !isPaused else { return }

        var targetY = currentY
        while isValidPosition(shape: currentShape, atX: gridX, atY: targetY + 1.0) {
            targetY += 1.0
        }

        let droppedRows = Int(floor(targetY)) - Int(floor(currentY))
        if droppedRows > 0 {
            score += droppedRows * 2
        }

        currentY = Double(Int(floor(targetY)))
        mergeCurrentPiece()
        score += 10
    }

    // MARK: - Linear, Wall-Kicked Rotation
    func rotate(dir: Int = 1) {
        guard !isDead && !isPaused else { return }
        guard let piece = TetrominoType(rawValue: currentShapeIndex) else { return }

        let nextRot = (currentRotation + dir + 4) % 4
        let testShape = piece.allRotationStates[nextRot]

        // Wall kicks: in-place (0), kick right 1 (+1), kick left 1 (-1), kick right 2 (+2), kick left 2 (-2)
        let kicks = [0, 1, -1, 2, -2, 3, -3]

        for offset in kicks {
            let testX = gridX + offset
            if isValidPosition(shape: testShape, atX: testX, atY: currentY) {
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

    // MARK: - Ghost Piece Projection
    var ghostY: Double {
        var testY = currentY
        while isValidPosition(shape: currentShape, atX: gridX, atY: testY + 1.0) {
            testY += 1.0
        }
        return Double(Int(floor(testY)))
    }

    // MARK: - Strict Boundary & Collision Checking
    func isValidPosition(shape: [[Int]], atX testX: Int, atY testY: Double) -> Bool {
        let checkRow = Int(ceil(testY))

        for r in 0..<shape.count {
            for c in 0..<shape[r].count {
                if shape[r][c] != 0 {
                    let col = testX + c
                    let row = checkRow + r

                    // STRICT HORIZONTAL BOUNDARIES: 0 <= col < 10
                    if col < 0 || col >= GameConfig.columns {
                        return false
                    }

                    // STRICT BOTTOM BOUNDARY: row < 18
                    if row >= GameConfig.rows {
                        return false
                    }

                    // ARENA BLOCK COLLISION
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
        let landingRow = Int(floor(currentY))

        for r in 0..<currentShape.count {
            for c in 0..<currentShape[r].count {
                if currentShape[r][c] != 0 {
                    let boardRow = landingRow + r
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

                // Stacker formula: score = (score * 1.5) + 75
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
            currentY: currentY,
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
