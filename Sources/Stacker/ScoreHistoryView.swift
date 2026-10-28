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

            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                    Text("High Score History")
                        .font(.system(size: 16, weight: .bold))
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
                .padding(.top, 16)

                Divider()
                    .background(Color.gray.opacity(0.4))

                // Score list
                if history.entries.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                        Text("No scores recorded yet")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        Text("Play a game and set your first record!")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.8))
                        Spacer()
                    }
                    .frame(height: 280)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(Array(history.entries.enumerated()), id: \.element.id) { index, entry in
                                HStack {
                                    // Rank badge
                                    Text("#\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(rankColor(index))
                                        .frame(width: 28, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(entry.score)")
                                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Text("\(entry.lines) lines • \(entry.formattedDate)")
                                            .font(.system(size: 10))
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
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(index == 0 ? Color.yellow.opacity(0.12) : Color.white.opacity(0.06))
                                )
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                    .frame(maxHeight: 320)
                }

                Divider()
                    .background(Color.gray.opacity(0.4))

                // Footer actions
                HStack {
                    if !history.entries.isEmpty {
                        Button("Clear History") {
                            ScoreHistoryManager.shared.clearHistory()
                            engine.highscore = 0
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.8))
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button("Close") {
                        engine.showHistory = false
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .frame(width: 270)
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
