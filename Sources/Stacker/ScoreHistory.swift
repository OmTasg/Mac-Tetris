import Foundation
import Combine

struct ScoreEntry: Codable, Identifiable {
    let id: UUID
    let score: Int
    let lines: Int
    let duration: TimeInterval
    let date: Date

    enum CodingKeys: String, CodingKey {
        case id, score, lines, duration, date
    }

    init(id: UUID = UUID(), score: Int, lines: Int, duration: TimeInterval, date: Date = Date()) {
        self.id = id
        self.score = score
        self.lines = lines
        self.duration = duration
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.score = try container.decode(Int.self, forKey: .score)
        self.lines = try container.decode(Int.self, forKey: .lines)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        self.date = try container.decode(Date.self, forKey: .date)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        formatTime(duration)
    }
}

struct HistoryStorage: Codable {
    var entries: [ScoreEntry]
    var totalPlayTime: Double
}

func formatTime(_ interval: TimeInterval) -> String {
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else if minutes > 0 {
        return "\(minutes)m \(seconds)s"
    } else {
        return "\(seconds)s"
    }
}

func formatClockTime(_ interval: TimeInterval) -> String {
    let totalSeconds = Int(interval)
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    let hours = totalSeconds / 3600

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

final class ScoreHistoryManager: ObservableObject {
    static let shared = ScoreHistoryManager()

    private let fileURL: URL

    @Published private(set) var entries: [ScoreEntry] = []
    @Published private(set) var totalPlayTime: Double = 0

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = appSupport.appendingPathComponent("Stacker", isDirectory: true)

        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        self.fileURL = directoryURL.appendingPathComponent("scores.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            entries = []
            totalPlayTime = 0
            return
        }

        // Try decoding new storage format with totalPlayTime
        if let storage = try? JSONDecoder().decode(HistoryStorage.self, from: data) {
            entries = storage.entries.sorted { $0.score > $1.score }
            totalPlayTime = storage.totalPlayTime
            return
        }

        // Fallback for previous [ScoreEntry] format
        if let oldEntries = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            entries = oldEntries.sorted { $0.score > $1.score }
            totalPlayTime = 0
            return
        }

        entries = []
        totalPlayTime = 0
    }

    func addPlayTime(_ seconds: Double) {
        guard seconds > 0 else { return }
        totalPlayTime += seconds
        save()
    }

    func record(score: Int, lines: Int, duration: TimeInterval) {
        guard score > 0 else { return }
        let newEntry = ScoreEntry(id: UUID(), score: score, lines: lines, duration: duration, date: Date())
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

    private func save() {
        let storage = HistoryStorage(entries: entries, totalPlayTime: totalPlayTime)
        guard let data = try? JSONEncoder().encode(storage) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
