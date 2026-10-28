import Foundation
import SwiftUI
import Combine

final class GameEngine: ObservableObject {
    @Published var arena: [[Int]]
    @Published var currentX: Double = 0
    @Published var currentY: Double = 0
    @Published var currentShape: [[Int]] = []
    @Published var currentShapeIndex: Int = 0
    @Published var currentRotation: Int = 0
    @Published var rotationDeg: Double = 0
    private var rotationDegGoal: Double = 0

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

    // Smooth line clear animation
    @Published var lineClearOffset: Double = 0
    @Published var lineClearBreakRow: Int? = nil
    private var lineClearYV: Double = 0

    // Key states
    private var isLeftPressed = false
    private var isRightPressed = false
    private var isDownPressed = false
    private var rotateTimer = 0

    private var velX: Double = 0
    private var velY: Double = 0

    private let bag = Bag()
    private var timer: Timer?

    init() {
        self.arena = Array(repeating: Array(repeating: 0, count: GameConfig.columns), count: GameConfig.rows)
        self.highscore = ScoreHistoryManager.shared.highestScore

        if let saved = StateManager.shared.loadState(), !saved.isDead {
            // Restore from saved state
            self.arena = saved.arenaMatrix
            self.currentX = saved.currentX
            self.currentY = saved.currentY
            self.currentShapeIndex = saved.currentShapeIndex
            self.currentRotation = saved.currentRotation
            self.currentShape = saved.currentShape
            self.nextShapeIndex = saved.nextShapeIndex
            self.bag.setBag(saved.bag)
            self.score = saved.score
            self.highscore = max(saved.highscore, ScoreHistoryManager.shared.highestScore)
            self.linesCleared = saved.linesCleared
            self.isDead = false
            self.isPaused = true // Open paused so user has time to orient
            self.rotationDeg = Double(saved.currentRotation) * (.pi / 2)
            self.rotationDegGoal = self.rotationDeg
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
        currentShape = pieceType.matrix
        currentRotation = 0
        rotationDeg = 0
        rotationDegGoal = 0

        // Spawn centered at the top
        let shapeWidth = currentShape[0].count
        let startCol = (GameConfig.columns - shapeWidth) / 2
        currentX = Double(startCol) * GameConfig.cellSize
        // Spawn just above the red line
        currentY = Double(GameConfig.deathLimitRow - shapeHeight) * GameConfig.cellSize
        if currentY < 0 {
            currentY = 0
        }

        velX = 0
        velY = GameConfig.verticalSpeed
    }

    func startLoop() {
        timer?.invalidate()
        // 60 FPS tick loop
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

        handleInput()

        // Smooth rotation easing
        rotationDeg = easeTo(rotationDegGoal, rotationDeg, speed: 0.3, threshold: 0.01)

        // Vertical movement
        let prevYY = Int(round(currentY / GameConfig.cellSize))
        currentY += velY

        if isCollision() {
            // Revert movement and snap to grid
            currentY -= velY
            currentY = Double(Int(round(currentY / GameConfig.cellSize))) * GameConfig.cellSize
            mergeCurrentPiece()
            score += 10
        } else {
            // Fast fall score bonus
            if isDownPressed && velY > GameConfig.verticalSpeed {
                let newYY = Int(round(currentY / GameConfig.cellSize))
                if newYY > prevYY {
                    score += (newYY - prevYY)
                }
            }
        }

        // Horizontal movement
        currentX += velX
        if isCollision() {
            currentX -= velX
        }

        // Keep within board horizontal boundaries
        let minX = -Double(whitespaceLeft) * GameConfig.cellSize
        let maxX = GameConfig.gameWidth - Double(shapeWidth - whitespaceRight) * GameConfig.cellSize
        currentX = min(max(currentX, minX), maxX)

        // Line clear smooth collapse
        if lineClearOffset < 0 {
            lineClearOffset = min(0, lineClearOffset + lineClearYV)
            if lineClearOffset == 0 {
                lineClearBreakRow = nil
                lineClearYV = 0
            }
        }

        if rotateTimer > 0 {
            rotateTimer -= 1
        }
    }

    // MARK: - Input Handling
    func setLeftPressed(_ pressed: Bool) {
        isLeftPressed = pressed
    }

    func setRightPressed(_ pressed: Bool) {
        isRightPressed = pressed
    }

    func setDownPressed(_ pressed: Bool) {
        isDownPressed = pressed
    }

    func togglePause() {
        guard !isDead else { return }
        isPaused.toggle()
        if isPaused {
            saveCurrentState()
        }
    }

    func rotate(dir: Int = 1) {
        guard rotateTimer <= 0, !isPaused, !isDead else { return }

        var newShape = currentShape
        rotateMatrix(&newShape, dir: dir)

        let prevShape = currentShape
        let prevX = currentX
        currentShape = newShape

        // Wall kick test (Stacker algorithm)
        var offset = 1.0
        let maxOffset = Double(newShape[0].count)

        while isCollision() {
            currentX += offset * GameConfig.cellSize
            offset = -(offset + (offset > 0 ? 1 : -1))

            if abs(offset) > maxOffset {
                // Revert
                currentX = prevX
                currentShape = prevShape
                return
            }
        }

        currentRotation = (currentRotation + dir + 4) % 4
        rotationDegGoal += Double(dir) * (.pi / 2)
        rotateTimer = GameConfig.rotateDelay
    }

    private func handleInput() {
        // Vertical speed
        velY = isDownPressed ? (GameConfig.verticalSpeed + GameConfig.boostSpeed) : GameConfig.verticalSpeed

        // Horizontal movement
        if isLeftPressed || isRightPressed {
            let dir: Double = isLeftPressed ? -1.0 : 1.0
            var allow = true

            // Prevent sliding into settled blocks
            for y in 0..<currentShape.count {
                for x in 0..<currentShape[y].count {
                    if currentShape[y][x] != 0 {
                        let by = yy + y
                        let bx = xx + x + Int(dir)
                        if by >= 0 && by < GameConfig.rows && bx >= 0 && bx < GameConfig.columns {
                            if arena[by][bx] != 0 {
                                allow = false
                            }
                        }
                    }
                }
            }

            if allow {
                velX = GameConfig.horizontalSpeed * dir
            } else {
                slideToTile()
            }
        } else {
            slideToTile()
        }
    }

    private func slideToTile() {
        let goalX = Double(xx) * GameConfig.cellSize
        velX = easeTo(goalX, currentX, speed: 0.2, threshold: 0.01) - currentX
    }

    // MARK: - Collision Detection
    var xx: Int {
        Int(round(currentX / GameConfig.cellSize))
    }

    var yy: Int {
        Int(round(currentY / GameConfig.cellSize))
    }

    var yyc: Int {
        Int(ceil(currentY / GameConfig.cellSize))
    }

    private func isCollision() -> Bool {
        // Bottom boundary
        let bottomY = currentY + Double(shapeHeight + whitespaceTop) * GameConfig.cellSize
        if bottomY > GameConfig.gameHeight {
            return true
        }

        // Left boundary
        if currentX + Double(whitespaceLeft) * GameConfig.cellSize < 0 {
            return true
        }

        // Right boundary
        if currentX + Double(shapeWidth - whitespaceRight) * GameConfig.cellSize > GameConfig.gameWidth {
            return true
        }

        // Arena block collisions
        for y in 0..<currentShape.count {
            for x in 0..<currentShape[y].count {
                if currentShape[y][x] != 0 {
                    let boardY = yyc + y
                    let boardX = xx + x

                    if boardY >= GameConfig.rows {
                        return true
                    }
                    if boardX < 0 || boardX >= GameConfig.columns {
                        return true
                    }
                    if boardY >= 0 && arena[boardY][boardX] != 0 {
                        return true
                    }
                }
            }
        }
        return false
    }

    // MARK: - Merging & Line Clearing
    private func mergeCurrentPiece() {
        guard let pieceType = TetrominoType(rawValue: currentShapeIndex) else { return }
        let colorIdx = pieceType.colorIndex

        for y in 0..<currentShape.count {
            for x in 0..<currentShape[y].count {
                if currentShape[y][x] != 0 {
                    let boardY = yy + y
                    let boardX = xx + x
                    if boardY >= 0 && boardY < GameConfig.rows && boardX >= 0 && boardX < GameConfig.columns {
                        arena[boardY][boardX] = colorIdx
                    }
                }
            }
        }

        // Check death condition: any block in rows 0..<4
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

        // Clear completed lines using Stacker's exact scoring algorithm
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

                // Visual break effect
                lineClearOffset -= GameConfig.cellSize
                lineClearBreakRow = r + 1
                if lineClearYV == 0 {
                    lineClearYV += 4.0 * (GameConfig.cellSize / 60.0)
                } else {
                    lineClearYV += 1.5 * (GameConfig.cellSize / 60.0)
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
            currentX: currentX,
            currentY: currentY,
            currentShapeIndex: currentShapeIndex,
            currentRotation: currentRotation,
            currentShape: currentShape,
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

    // MARK: - Helper calculations
    var currentColor: Color {
        TetrominoType(rawValue: currentShapeIndex)?.color ?? .white
    }

    var nextColor: Color {
        TetrominoType(rawValue: nextShapeIndex)?.color ?? .white
    }

    var nextShapeMatrix: [[Int]] {
        TetrominoType(rawValue: nextShapeIndex)?.matrix ?? []
    }

    var shapeWidth: Int {
        currentShape.first?.count ?? 0
    }

    var shapeHeight: Int {
        var h = currentShape.count
        for row in currentShape {
            if row.allSatisfy({ $0 == 0 }) {
                h -= 1
            }
        }
        return h
    }

    var whitespaceTop: Int {
        var count = 0
        for row in currentShape {
            if row.allSatisfy({ $0 == 0 }) {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    var whitespaceLeft: Int {
        guard !currentShape.isEmpty else { return 0 }
        var blanks = 0
        for x in 0..<currentShape[0].count {
            var colEmpty = true
            for y in 0..<currentShape.count {
                if currentShape[y][x] != 0 {
                    colEmpty = false
                    break
                }
            }
            if colEmpty {
                blanks += 1
            } else {
                break
            }
        }
        return blanks
    }

    var whitespaceRight: Int {
        guard !currentShape.isEmpty else { return 0 }
        var blanks = 0
        for x in stride(from: currentShape[0].count - 1, through: 0, by: -1) {
            var colEmpty = true
            for y in 0..<currentShape.count {
                if currentShape[y][x] != 0 {
                    colEmpty = false
                    break
                }
            }
            if colEmpty {
                blanks += 1
            } else {
                break
            }
        }
        return blanks
    }
}

// Matrix rotation utility
func rotateMatrix(_ matrix: inout [[Int]], dir: Int) {
    let n = matrix.count
    // Transpose
    for y in 0..<n {
        for x in 0..<y {
            let temp = matrix[x][y]
            matrix[x][y] = matrix[y][x]
            matrix[y][x] = temp
        }
    }
    // Clockwise (dir = 1): reverse each row
    // Counter-clockwise (dir = -1): reverse array of rows
    if dir == 1 {
        for i in 0..<matrix.count {
            matrix[i].reverse()
        }
    } else {
        matrix.reverse()
    }
}

func easeTo(_ goal: Double, _ value: Double, speed: Double, threshold: Double) -> Double {
    if abs(goal - value) <= threshold {
        return goal
    }
    return value + (goal - value) * speed
}

