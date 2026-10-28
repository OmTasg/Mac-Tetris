import Foundation

struct SavedGameState: Codable {
    let arenaMatrix: [[Int]]
    let gridX: Int
    let currentY: Double
    let currentShapeIndex: Int
    let currentRotation: Int
    let nextShapeIndex: Int
    let bag: [Int]
    let score: Int
    let highscore: Int
    let linesCleared: Int
    let isDead: Bool
    let isPaused: Bool
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
