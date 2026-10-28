import SwiftUI

struct ScoreHistoryView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject private var history = ScoreHistoryManager.shared

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.showHistory = false
                }

            VStack(spacing: 10) {
                // Header
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                    Text("High Score History")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        engine.showHistory = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                // Total Play Time Pill (Cumulative active time in app & current run)
                HStack(spacing: 10) {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.cyan)
                            .font(.system(size: 11))
                        Text("Total:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                        Text(formatTime(history.totalPlayTime))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Text("•")
                        .foregroundColor(.gray.opacity(0.4))

                    HStack(spacing: 5) {
                        Text("Current:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                        Text(formatClockTime(engine.currentRunTime))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                )

                Divider()
                    .background(Color.gray.opacity(0.4))

                // Score list with per-run time tracking
                if history.entries.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                        Text("No scores recorded yet")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        Text("Play a game and set your first record!")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.8))
                        Spacer()
                    }
                    .frame(height: 250)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(Array(history.entries.enumerated()), id: \.element.id) { index, entry in
                                HStack {
                                    // Rank badge
                                    Text("#\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(rankColor(index))
                                        .frame(width: 26, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(entry.score)")
                                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        HStack(spacing: 4) {
                                            Text("\(entry.lines) lines")
                                            Text("•")
                                            Text("⏱ \(entry.formattedDuration)")
                                            Text("•")
                                            Text(entry.formattedDate)
                                        }
                                        .font(.system(size: 9.5))
                                        .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    if index == 0 {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 12))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(index == 0 ? Color.yellow.opacity(0.12) : Color.white.opacity(0.06))
                                )
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                    .frame(maxHeight: 280)
                }

                Divider()
                    .background(Color.gray.opacity(0.4))

                // Footer (No Clear History button)
                HStack {
                    Spacer()
                    Button("Close") {
                        engine.showHistory = false
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .frame(width: 272)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#161616"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(radius: 20)
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 0: return .yellow
        case 1: return Color(hex: "#D8D8D8")
        case 2: return Color(hex: "#CD7F32")
        default: return .gray
        }
    }
}
