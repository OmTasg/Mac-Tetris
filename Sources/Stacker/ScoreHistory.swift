import Foundation
import Combine

struct ScoreEntry: Codable, Identifiable {
    let id: UUID
    let score: Int
    let lines: Int
    let date: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

final class ScoreHistoryManager: ObservableObject {
    static let shared = ScoreHistoryManager()

    private let fileURL: URL

    @Published private(set) var entries: [ScoreEntry] = []

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = appSupport.appendingPathComponent("Stacker", isDirectory: true)

        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        self.fileURL = directoryURL.appendingPathComponent("scores.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ScoreEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded.sorted { $0.score > $1.score }
    }

    func record(score: Int, lines: Int) {
        guard score > 0 else { return }
        let newEntry = ScoreEntry(id: UUID(), score: score, lines: lines, date: Date())
        entries.append(newEntry)
        entries.sort { $0.score > $1.score }
        if entries.count > 50 {
            entries = Array(entries.prefix(50))
        }
        save()
    }

    var highestScore: Int {
        entries.first?.score ?? 0
    }

    func clearHistory() {
        entries.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
