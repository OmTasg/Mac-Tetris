import Foundation
import AppKit
import SwiftUI
import Combine

final class StudyLockManager: ObservableObject {
    static let shared = StudyLockManager()

    @Published private(set) var isLocked: Bool = false
    @Published private(set) var lockedUntil: Date? = nil
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var totalDurationSeconds: Int = 0
    @Published private(set) var formattedRemainingTime: String = "00:00"
    @Published private(set) var sessionLabel: String = "Study Session"
    @Published private(set) var isStrictLock: Bool = false
    @Published var sessionJustFinished: Bool = false
    @Published var currentQuoteIndex: Int = 0

    // Interactive UI State (avoids @State compiler macro requirements)
    @Published var showEmergencyUnlock: Bool = false
    @Published var typedPhrase: String = ""
    @Published var unlockError: Bool = false
    @Published var setupSelectedMinutes: Int = 25
    @Published var setupSessionLabel: String = "Study Session"
    @Published var setupStrict: Bool = false

    private var countdownTimer: Timer?
    private let frictionPhrase = "I am giving up on my study goals and want to procrastinate"

    let quotes: [String] = [
        "Focus is a muscle. Every minute you stay on task makes you sharper. 🧠",
        "The secret to getting ahead is getting started. Back to the books! 📚",
        "Tetris will still be here when you finish. Do your future self a favor. ✨",
        "Deep work produces deep results. Eliminate the noise. 🎧",
        "Small disciplines repeated with consistency lead to great achievements. 🎯",
        "Stay with the hard problem. That's where the growth happens. 💡",
        "You didn't come this far to only come this far. Keep going! 🚀"
    ]

    var currentQuote: String {
        quotes[currentQuoteIndex % quotes.count]
    }

    var progress: Double {
        guard totalDurationSeconds > 0 else { return 0 }
        let elapsed = Double(totalDurationSeconds - remainingSeconds)
        return min(1.0, max(0.0, elapsed / Double(totalDurationSeconds)))
    }

    var formattedEndTime: String {
        guard let lockedUntil = lockedUntil else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lockedUntil)
    }

    var requiredFrictionPhrase: String {
        frictionPhrase
    }

    private init() {
        checkSavedLock()
    }

    private func checkSavedLock() {
        let untilTimestamp = UserDefaults.standard.double(forKey: "stacker_lock_until")
        if untilTimestamp > 0 {
            let targetDate = Date(timeIntervalSince1970: untilTimestamp)
            if targetDate > Date() {
                self.lockedUntil = targetDate
                self.totalDurationSeconds = UserDefaults.standard.integer(forKey: "stacker_lock_total_seconds")
                self.sessionLabel = UserDefaults.standard.string(forKey: "stacker_lock_label") ?? "Study Session"
                self.isStrictLock = UserDefaults.standard.bool(forKey: "stacker_lock_strict")
                self.isLocked = true
                self.updateRemainingTime()
                self.startTimer()
                return
            }
        }
        clearSavedData()
    }

    func startLock(durationMinutes: Int, label: String = "Study Session", strict: Bool = false) {
        let totalSecs = max(60, durationMinutes * 60)
        let targetDate = Date().addingTimeInterval(Double(totalSecs))

        self.lockedUntil = targetDate
        self.totalDurationSeconds = totalSecs
        self.sessionLabel = label.isEmpty ? "Study Session" : label
        self.isStrictLock = strict
        self.isLocked = true
        self.sessionJustFinished = false
        self.currentQuoteIndex = Int.random(in: 0..<quotes.count)

        UserDefaults.standard.set(targetDate.timeIntervalSince1970, forKey: "stacker_lock_until")
        UserDefaults.standard.set(totalSecs, forKey: "stacker_lock_total_seconds")
        UserDefaults.standard.set(self.sessionLabel, forKey: "stacker_lock_label")
        UserDefaults.standard.set(strict, forKey: "stacker_lock_strict")

        updateRemainingTime()
        startTimer()
    }

    func emergencyUnlock(typedPhrase: String) -> Bool {
        guard !isStrictLock else { return false }
        let normalized = typedPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized == frictionPhrase {
            cancelLock(isEmergency: true)
            return true
        }
        return false
    }

    func cancelLock(isEmergency: Bool = false) {
        countdownTimer?.invalidate()
        countdownTimer = nil
        clearSavedData()
        self.isLocked = false
        self.lockedUntil = nil
        self.remainingSeconds = 0
        self.formattedRemainingTime = "00:00"
        if !isEmergency {
            self.sessionJustFinished = true
            NSSound(named: "Glass")?.play()
        }
    }

    private func clearSavedData() {
        UserDefaults.standard.removeObject(forKey: "stacker_lock_until")
        UserDefaults.standard.removeObject(forKey: "stacker_lock_total_seconds")
        UserDefaults.standard.removeObject(forKey: "stacker_lock_label")
        UserDefaults.standard.removeObject(forKey: "stacker_lock_strict")
    }

    private func startTimer() {
        countdownTimer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        self.countdownTimer = t
    }

    private func tick() {
        guard let lockedUntil = lockedUntil else {
            cancelLock(isEmergency: false)
            return
        }

        let diff = Int(ceil(lockedUntil.timeIntervalSince(Date())))
        if diff <= 0 {
            // Lock expired naturally!
            cancelLock(isEmergency: false)
        } else {
            self.remainingSeconds = diff
            self.formattedRemainingTime = formatSeconds(diff)
            if diff % 60 == 0 {
                currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
            }
        }
    }

    private func updateRemainingTime() {
        guard let lockedUntil = lockedUntil else { return }
        let diff = max(0, Int(ceil(lockedUntil.timeIntervalSince(Date()))))
        self.remainingSeconds = diff
        self.formattedRemainingTime = formatSeconds(diff)
    }

    private func formatSeconds(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
