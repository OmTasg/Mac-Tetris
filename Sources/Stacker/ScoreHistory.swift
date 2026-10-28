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
    var analytics: GameAnalytics?

    enum CodingKeys: String, CodingKey {
        case entries, totalPlayTime, analytics
    }

    init(entries: [ScoreEntry], totalPlayTime: Double, analytics: GameAnalytics? = nil) {
        self.entries = entries
        self.totalPlayTime = totalPlayTime
        self.analytics = analytics
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entries = try c.decodeIfPresent([ScoreEntry].self, forKey: .entries) ?? []
        totalPlayTime = try c.decodeIfPresent(Double.self, forKey: .totalPlayTime) ?? 0
        analytics = try c.decodeIfPresent(GameAnalytics.self, forKey: .analytics)
    }
}

struct GameAnalytics: Codable {
    var totalGamesPlayed: Int
    var totalPlayTime: Double
    var totalScore: Int
    var totalLinesCleared: Int
    var totalPiecesPlaced: Int

    var longestRunDuration: Double
    var dangerZoneSurvivalTime: Double // Time spent surviving with stack at row <= 6

    var hardDropCount: Int
    var hardDropTotalRows: Int
    var softDropCount: Int

    var singlesCount: Int
    var doublesCount: Int
    var triplesCount: Int
    var tetrisCount: Int

    var pieceCounts: [Int] // 0: T, 1: I, 2: O, 3: L, 4: J, 5: S, 6: Z

    var highestScore: Int
    var highestLines: Int

    init(
        totalGamesPlayed: Int = 0,
        totalPlayTime: Double = 0,
        totalScore: Int = 0,
        totalLinesCleared: Int = 0,
        totalPiecesPlaced: Int = 0,
        longestRunDuration: Double = 0,
        dangerZoneSurvivalTime: Double = 0,
        hardDropCount: Int = 0,
        hardDropTotalRows: Int = 0,
        softDropCount: Int = 0,
        singlesCount: Int = 0,
        doublesCount: Int = 0,
        triplesCount: Int = 0,
        tetrisCount: Int = 0,
        pieceCounts: [Int] = [0, 0, 0, 0, 0, 0, 0],
        highestScore: Int = 0,
        highestLines: Int = 0
    ) {
        self.totalGamesPlayed = totalGamesPlayed
        self.totalPlayTime = totalPlayTime
        self.totalScore = totalScore
        self.totalLinesCleared = totalLinesCleared
        self.totalPiecesPlaced = totalPiecesPlaced
        self.longestRunDuration = longestRunDuration
        self.dangerZoneSurvivalTime = dangerZoneSurvivalTime
        self.hardDropCount = hardDropCount
        self.hardDropTotalRows = hardDropTotalRows
        self.softDropCount = softDropCount
        self.singlesCount = singlesCount
        self.doublesCount = doublesCount
        self.triplesCount = triplesCount
        self.tetrisCount = tetrisCount
        self.pieceCounts = pieceCounts
        self.highestScore = highestScore
        self.highestLines = highestLines
    }

    enum CodingKeys: String, CodingKey {
        case totalGamesPlayed, totalPlayTime, totalScore, totalLinesCleared, totalPiecesPlaced
        case longestRunDuration, dangerZoneSurvivalTime
        case hardDropCount, hardDropTotalRows, softDropCount
        case singlesCount, doublesCount, triplesCount, tetrisCount
        case pieceCounts, highestScore, highestLines
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalGamesPlayed = try c.decodeIfPresent(Int.self, forKey: .totalGamesPlayed) ?? 0
        totalPlayTime = try c.decodeIfPresent(Double.self, forKey: .totalPlayTime) ?? 0
        totalScore = try c.decodeIfPresent(Int.self, forKey: .totalScore) ?? 0
        totalLinesCleared = try c.decodeIfPresent(Int.self, forKey: .totalLinesCleared) ?? 0
        totalPiecesPlaced = try c.decodeIfPresent(Int.self, forKey: .totalPiecesPlaced) ?? 0
        longestRunDuration = try c.decodeIfPresent(Double.self, forKey: .longestRunDuration) ?? 0
        dangerZoneSurvivalTime = try c.decodeIfPresent(Double.self, forKey: .dangerZoneSurvivalTime) ?? 0
        hardDropCount = try c.decodeIfPresent(Int.self, forKey: .hardDropCount) ?? 0
        hardDropTotalRows = try c.decodeIfPresent(Int.self, forKey: .hardDropTotalRows) ?? 0
        softDropCount = try c.decodeIfPresent(Int.self, forKey: .softDropCount) ?? 0
        singlesCount = try c.decodeIfPresent(Int.self, forKey: .singlesCount) ?? 0
        doublesCount = try c.decodeIfPresent(Int.self, forKey: .doublesCount) ?? 0
        triplesCount = try c.decodeIfPresent(Int.self, forKey: .triplesCount) ?? 0
        tetrisCount = try c.decodeIfPresent(Int.self, forKey: .tetrisCount) ?? 0
        pieceCounts = try c.decodeIfPresent([Int].self, forKey: .pieceCounts) ?? [0, 0, 0, 0, 0, 0, 0]
        highestScore = try c.decodeIfPresent(Int.self, forKey: .highestScore) ?? 0
        highestLines = try c.decodeIfPresent(Int.self, forKey: .highestLines) ?? 0
    }

    var tetrisRate: Double {
        let linesFromTetrises = tetrisCount * 4
        guard totalLinesCleared > 0 else { return 0 }
        return min(100.0, (Double(linesFromTetrises) / Double(totalLinesCleared)) * 100.0)
    }

    var averageRunDuration: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return totalPlayTime / Double(totalGamesPlayed)
    }

    var averageScore: Int {
        guard totalGamesPlayed > 0 else { return 0 }
        return totalScore / totalGamesPlayed
    }

    var piecesPerMinute: Double {
        let minutes = totalPlayTime / 60.0
        guard minutes >= 0.1 else { return 0 }
        return Double(totalPiecesPlaced) / minutes
    }

    var scorePerMinute: Double {
        let minutes = totalPlayTime / 60.0
        guard minutes >= 0.1 else { return 0 }
        return Double(totalScore) / minutes
    }

    var hardDropPercentage: Double {
        let total = hardDropCount + softDropCount
        guard total > 0 else { return 0 }
        return (Double(hardDropCount) / Double(total)) * 100.0
    }

    var favoritePieceIndex: Int? {
        guard pieceCounts.reduce(0, +) > 0 else { return nil }
        return pieceCounts.indices.max(by: { pieceCounts[$0] < pieceCounts[$1] })
    }

    var archetype: (title: String, subtitle: String, icon: String, color: String) {
        if dangerZoneSurvivalTime >= 30 && dangerZoneSurvivalTime > totalPlayTime * 0.12 {
            return ("Danger Walker", "Thrives inches from the ceiling line", "flame.fill", "#FF0D72")
        } else if tetrisRate >= 35 && tetrisCount >= 2 {
            return ("Tetris Architect", "Master of massive 4-line quad clears", "sparkles", "#F538FF")
        } else if hardDropPercentage >= 60 && hardDropCount >= 20 {
            return ("Speed Demon", "Aggressively slams pieces with spacebar", "bolt.fill", "#0DC2FF")
        } else if longestRunDuration >= 300 {
            return ("Endurance Titan", "Survivor of long endurance runs", "shield.fill", "#0DFF72")
        } else if totalGamesPlayed >= 5 {
            return ("Tactical Stacker", "Balanced and methodical gameplay", "target", "#FFE138")
        } else {
            return ("Rising Stacker", "Sharpening stacking reflexes", "gamecontroller.fill", "#3877FF")
        }
    }
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
    @Published private(set) var analytics: GameAnalytics = GameAnalytics()

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
            analytics = GameAnalytics()
            return
        }

        // Try decoding new storage format with totalPlayTime and analytics
        if let storage = try? JSONDecoder().decode(HistoryStorage.self, from: data) {
            entries = storage.entries.sorted { $0.score > $1.score }
            totalPlayTime = storage.totalPlayTime
            if var existingAnalytics = storage.analytics {
                existingAnalytics.totalPlayTime = max(existingAnalytics.totalPlayTime, storage.totalPlayTime)
                analytics = existingAnalytics
            } else {
                analytics = seedAnalyticsFromHistory(entries: entries, totalPlayTime: totalPlayTime)
            }
            return
        }

        // Fallback for previous [ScoreEntry] format
        if let oldEntries = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            entries = oldEntries.sorted { $0.score > $1.score }
            totalPlayTime = 0
            analytics = seedAnalyticsFromHistory(entries: entries, totalPlayTime: 0)
            return
        }

        entries = []
        totalPlayTime = 0
        analytics = GameAnalytics()
    }

    private func seedAnalyticsFromHistory(entries: [ScoreEntry], totalPlayTime: Double) -> GameAnalytics {
        var a = GameAnalytics()
        a.totalGamesPlayed = entries.count
        a.totalPlayTime = totalPlayTime
        a.totalScore = entries.reduce(0) { $0 + $1.score }
        a.totalLinesCleared = entries.reduce(0) { $0 + $1.lines }
        a.highestScore = entries.map(\.score).max() ?? 0
        a.highestLines = entries.map(\.lines).max() ?? 0
        a.longestRunDuration = entries.map(\.duration).max() ?? 0
        return a
    }

    func addPlayTime(_ seconds: Double) {
        guard seconds > 0 else { return }
        totalPlayTime += seconds
        analytics.totalPlayTime += seconds
        save()
    }

    func addDangerZoneTime(_ seconds: Double) {
        guard seconds > 0 else { return }
        analytics.dangerZoneSurvivalTime += seconds
    }

    func recordPiecePlaced(shapeIndex: Int) {
        analytics.totalPiecesPlaced += 1
        if shapeIndex >= 0 && shapeIndex < analytics.pieceCounts.count {
            analytics.pieceCounts[shapeIndex] += 1
        }
    }

    func recordHardDrop(rows: Int) {
        analytics.hardDropCount += 1
        analytics.hardDropTotalRows += max(0, rows)
    }

    func recordSoftDrop() {
        analytics.softDropCount += 1
    }

    func recordLineClears(count: Int) {
        guard count > 0 else { return }
        analytics.totalLinesCleared += count
        switch count {
        case 1: analytics.singlesCount += 1
        case 2: analytics.doublesCount += 1
        case 3: analytics.triplesCount += 1
        case 4: analytics.tetrisCount += 1
        default: break
        }
    }

    func recordGameFinished(score: Int, lines: Int, duration: TimeInterval) {
        analytics.totalGamesPlayed += 1
        analytics.totalScore += score
        analytics.longestRunDuration = max(analytics.longestRunDuration, duration)
        analytics.highestScore = max(analytics.highestScore, score)
        analytics.highestLines = max(analytics.highestLines, lines)
        record(score: score, lines: lines, duration: duration)
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
        entries.first?.score ?? analytics.highestScore
    }

    func save() {
        let storage = HistoryStorage(entries: entries, totalPlayTime: totalPlayTime, analytics: analytics)
        guard let data = try? JSONEncoder().encode(storage) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
