import SwiftUI

// MARK: - Active Study Lock Full Overlay View
struct StudyLockOverlayView: View {
    @ObservedObject var lockManager = StudyLockManager.shared
    @ObservedObject var engine: GameEngine
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            // Dark focused background
            Color(hex: "#0e0e11")
                .ignoresSafeArea()

            if lockManager.sessionJustFinished {
                sessionCompletedContent
            } else {
                activeLockContent
            }

            if lockManager.showEmergencyUnlock {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                    .onTapGesture {
                        lockManager.showEmergencyUnlock = false
                        lockManager.typedPhrase = ""
                        lockManager.unlockError = false
                    }

                emergencyUnlockSheet
                    .transition(.opacity)
            }
        }
        .frame(width: GameConfig.gameWidth, height: GameConfig.gameHeight)
    }

    // MARK: - Active Lock Screen
    private var activeLockContent: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 12)

            // Header Lock Badge
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.yellow)
                Text("STUDY LOCK ACTIVE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )

            Text(lockManager.sessionLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)

            Spacer()

            // Large Glowing Countdown
            VStack(spacing: 4) {
                Text(lockManager.formattedRemainingTime)
                    .font(.system(size: 46, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .yellow.opacity(0.3), radius: 10, x: 0, y: 0)

                Text("Locked until \(lockManager.formattedEndTime)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * CGFloat(lockManager.progress)), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 36)

            // Total Successful Lock Time Tracker
            HStack(spacing: 5) {
                Image(systemName: "hourglass.bottomhalf.filled")
                    .font(.system(size: 9.5))
                    .foregroundColor(.cyan)
                Text("\(lockManager.totalLockedMinutes) min successfully locked")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.95))

                if lockManager.totalLockedMinutes >= 60 {
                    Text("(\(lockManager.formattedTotalLockedTime))")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4.5)
            .background(Color.cyan.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 0.5)
            )

            Spacer()

            // Motivational Quote Card
            VStack(alignment: .center, spacing: 6) {
                Text(lockManager.currentQuote)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 260)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )

            // Accountability Track Record
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                    Text("\(lockManager.completedCount) Completed")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.gray)
                }

                if lockManager.giveUpCount > 0 {
                    Text("•").foregroundColor(.gray.opacity(0.4)).font(.system(size: 8))
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 8.5))
                            .foregroundColor(.red)
                        Text("\(lockManager.giveUpCount) Gave Up")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.red.opacity(0.85))
                    }
                }
            }

            Spacer().frame(height: 4)

            // Bottom Actions
            VStack(spacing: 10) {
                Button(action: {
                    AppDelegate.shared?.hidePanel()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 10))
                        Text("Hide Stacker (Esc or ⌘W)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 240, height: 34)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    lockManager.showEmergencyUnlock.toggle()
                    if lockManager.showEmergencyUnlock {
                        AppDelegate.shared?.activateAndMakeKey()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.isFieldFocused = true
                        }
                    }
                }) {
                    Text(lockManager.showEmergencyUnlock ? "Hide Emergency Options" : "Emergency Unlock...")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                        .underline()
                }
                .buttonStyle(.plain)
            }

            Spacer().frame(height: 10)
        }
    }

    // MARK: - Session Completed Screen
    private var sessionCompletedContent: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 0)

            VStack(spacing: 6) {
                Text("STUDY SESSION COMPLETE!")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text("Great job staying focused and productive.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                HStack(spacing: 4) {
                    Image(systemName: "hourglass.bottomhalf.filled")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text("Total Locked: \(lockManager.totalLockedMinutes) min (\(lockManager.formattedTotalLockedTime))")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                .padding(.top, 4)
            }

            Spacer()

            VStack(spacing: 10) {
                Button(action: {
                    lockManager.sessionJustFinished = false
                    engine.unpause()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume Stacker")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 220, height: 36)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    lockManager.sessionJustFinished = false
                    engine.activeModalTab = .focusLock
                    engine.showHistory = true
                }) {
                    Text("Start Another Study Block")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Friction-based Emergency Unlock Sheet
    private var emergencyUnlockSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚠️ Emergency Unlock")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red)
                Spacer()
                Button("Close") {
                    lockManager.showEmergencyUnlock = false
                    lockManager.typedPhrase = ""
                    lockManager.unlockError = false
                }
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .buttonStyle(.plain)
            }

            Divider().background(Color.gray.opacity(0.3))

            if lockManager.isStrictLock {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)

                    Text("Strict Mode Active")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)

                    Text("You enabled Strict Mode for this session. Stacker cannot be unlocked early under any circumstances.\n\nTake a deep breath and return to studying! 📚")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.vertical, 16)
            } else {
                Text("To prevent impulsive procrastination, you must type the exact sentence below character-for-character to unlock:")
                    .font(.system(size: 10.5))
                    .foregroundColor(.gray)
                    .lineSpacing(2)

                // Accountability Warning Banner
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                    Text("Accountability: Given up \(lockManager.giveUpCount) time\(lockManager.giveUpCount == 1 ? "" : "s"). Breaking this will make it \(lockManager.giveUpCount + 1)!")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.red.opacity(0.95))
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.12))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red.opacity(0.3), lineWidth: 0.5)
                )

                Text("\"\(lockManager.requiredFrictionPhrase)\"")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.yellow)
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)

                TextField("Type the phrase here to unlock...", text: $lockManager.typedPhrase)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(.white)
                    .focused($isFieldFocused)
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(lockManager.unlockError ? Color.red : (isFieldFocused ? Color.yellow.opacity(0.8) : Color.gray.opacity(0.4)), lineWidth: 1)
                    )
                    .onSubmit {
                        attemptUnlock()
                    }

                HStack {
                    Spacer()
                    Button("Cancel") {
                        lockManager.showEmergencyUnlock = false
                        lockManager.typedPhrase = ""
                        lockManager.unlockError = false
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .buttonStyle(.plain)

                    let isMatch = lockManager.typedPhrase.trimmingCharacters(in: .whitespacesAndNewlines) == lockManager.requiredFrictionPhrase

                    Button("Break Lock") {
                        attemptUnlock()
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isMatch ? .white : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isMatch ? Color.red : Color.white.opacity(0.1))
                    .cornerRadius(6)
                    .disabled(!isMatch)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 270)
        .background(Color(hex: "#1a1a1d"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 10)
        .onAppear {
            AppDelegate.shared?.activateAndMakeKey()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.isFieldFocused = true
            }
        }
    }

    private func attemptUnlock() {
        if lockManager.emergencyUnlock(typedPhrase: lockManager.typedPhrase) {
            lockManager.showEmergencyUnlock = false
            lockManager.typedPhrase = ""
            lockManager.unlockError = false
        } else {
            lockManager.unlockError = true
        }
    }
}

// MARK: - Study Lock Setup Configuration View (Tabs in Modal Sheet)
struct StudyLockSetupView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var lockManager = StudyLockManager.shared

    private let presets: [Int] = [15, 25, 45, 60, 90, 120]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("Study Lock / Focus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text("Lock Stacker to focus without downtime distractions.")
                    .font(.system(size: 10.5))
                    .foregroundColor(.gray)
            }

            // Focus & Accountability Stats Summary Card
            HStack(spacing: 0) {
                // 1. Completed
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("\(lockManager.completedCount)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Text("Completed")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 22)

                // 2. Total Time Locked
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "hourglass.bottomhalf.filled")
                            .font(.system(size: 9.5))
                            .foregroundColor(.cyan)
                        Text(lockManager.formattedTotalLockedTime)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    Text("Total Locked")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 22)

                // 3. Gave Up
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 9))
                            .foregroundColor(lockManager.giveUpCount > 0 ? .red : .gray)
                        Text("\(lockManager.giveUpCount)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(lockManager.giveUpCount > 0 ? .red : .white.opacity(0.8))
                    }
                    Text("Gave Up")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 22)

                // 4. Focus Rate
                VStack(spacing: 2) {
                    Text("\(String(format: "%.0f%%", lockManager.disciplineRate))")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(lockManager.disciplineRate >= 80 ? .green : (lockManager.disciplineRate >= 50 ? .yellow : .red))
                    Text("Discipline")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )

            // Presets
            VStack(alignment: .leading, spacing: 5) {
                Text("DURATION")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.8))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(presets, id: \.self) { mins in
                        Button(action: {
                            lockManager.setupSelectedMinutes = mins
                        }) {
                            VStack(spacing: 2) {
                                Text(formatPresetLabel(mins))
                                    .font(.system(size: 12, weight: .bold))
                                Text(presetSubtitle(mins))
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .foregroundColor(lockManager.setupSelectedMinutes == mins ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(lockManager.setupSelectedMinutes == mins ? Color.yellow : Color.white.opacity(0.08))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Custom Slider
            VStack(spacing: 4) {
                HStack {
                    Text("Custom Duration")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(lockManager.setupSelectedMinutes) min")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }

                Slider(value: Binding(
                    get: { Double(lockManager.setupSelectedMinutes) },
                    set: { lockManager.setupSelectedMinutes = Int($0) }
                ), in: 5...180, step: 5)
                .accentColor(.yellow)
            }

            // Strict Mode Toggle
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strict Lock")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Disables emergency phrase unlock")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                Spacer()
                Toggle("", isOn: $lockManager.setupStrict)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)

            // Saved Game Note
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 10))
                Text("Your active game and score are safely saved.")
                    .font(.system(size: 9.5))
                    .foregroundColor(.gray.opacity(0.9))
            }

            // Start Lock Button
            Button(action: {
                engine.saveCurrentState()
                engine.autoPause()
                engine.showHistory = false
                lockManager.startLock(
                    durationMinutes: lockManager.setupSelectedMinutes,
                    label: lockManager.setupSessionLabel,
                    strict: lockManager.setupStrict
                )
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                    Text("Lock Stacker for \(lockManager.setupSelectedMinutes)m")
                        .font(.system(size: 12.5, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.yellow)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func formatPresetLabel(_ mins: Int) -> String {
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return m == 0 ? "\(h) hr" : "\(h)h \(m)m"
        }
        return "\(mins) min"
    }

    private func presetSubtitle(_ mins: Int) -> String {
        switch mins {
        case 15: return "Sprint"
        case 25: return "Pomodoro"
        case 45: return "Deep Focus"
        case 60: return "1 Hour"
        case 90: return "Long Block"
        case 120: return "2 Hours"
        default: return "Custom"
        }
    }
}
