import Foundation

struct SavedGameState: Codable {
    let arenaMatrix: [[Int]]
    let gridX: Int
    let gridY: Int
    let currentShapeIndex: Int
    let currentRotation: Int
    let nextShapeIndex: Int
    let bag: [Int]
    let score: Int
    let highscore: Int
    let linesCleared: Int
    let currentRunTime: Double
    let isDead: Bool
    let isPaused: Bool

    enum CodingKeys: String, CodingKey {
        case arenaMatrix, gridX, gridY, currentShapeIndex, currentRotation, nextShapeIndex, bag, score, highscore, linesCleared, currentRunTime, isDead, isPaused
    }

    init(
        arenaMatrix: [[Int]],
        gridX: Int,
        gridY: Int,
        currentShapeIndex: Int,
        currentRotation: Int,
        nextShapeIndex: Int,
        bag: [Int],
        score: Int,
        highscore: Int,
        linesCleared: Int,
        currentRunTime: Double,
        isDead: Bool,
        isPaused: Bool
    ) {
        self.arenaMatrix = arenaMatrix
        self.gridX = gridX
        self.gridY = gridY
        self.currentShapeIndex = currentShapeIndex
        self.currentRotation = currentRotation
        self.nextShapeIndex = nextShapeIndex
        self.bag = bag
        self.score = score
        self.highscore = highscore
        self.linesCleared = linesCleared
        self.currentRunTime = currentRunTime
        self.isDead = isDead
        self.isPaused = isPaused
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.arenaMatrix = try container.decode([[Int]].self, forKey: .arenaMatrix)
        self.gridX = try container.decode(Int.self, forKey: .gridX)
        self.gridY = try container.decode(Int.self, forKey: .gridY)
        self.currentShapeIndex = try container.decode(Int.self, forKey: .currentShapeIndex)
        self.currentRotation = try container.decode(Int.self, forKey: .currentRotation)
        self.nextShapeIndex = try container.decode(Int.self, forKey: .nextShapeIndex)
        self.bag = try container.decode([Int].self, forKey: .bag)
        self.score = try container.decode(Int.self, forKey: .score)
        self.highscore = try container.decode(Int.self, forKey: .highscore)
        self.linesCleared = try container.decode(Int.self, forKey: .linesCleared)
        self.currentRunTime = try container.decodeIfPresent(Double.self, forKey: .currentRunTime) ?? 0
        self.isDead = try container.decode(Bool.self, forKey: .isDead)
        self.isPaused = try container.decode(Bool.self, forKey: .isPaused)
    }
}

final class StateManager {
    static let shared = StateManager()

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = appSupport.appendingPathComponent("Stacker", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        self.fileURL = directoryURL.appendingPathComponent("gamestate.json")
    }

    func saveState(_ state: SavedGameState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func loadState() -> SavedGameState? {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(SavedGameState.self, from: data) else {
            return nil
        }
        return state
    }

    func clearState() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
