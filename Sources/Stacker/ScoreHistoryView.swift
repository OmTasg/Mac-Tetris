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

            VStack(spacing: 8) {
                // Top Tab Switcher & Close Button
                HStack(spacing: 6) {
                    Button(action: {
                        engine.activeModalTab = .leaderboard
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 11))
                            Text("Leaderboard")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(engine.activeModalTab == .leaderboard ? .white : .gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(engine.activeModalTab == .leaderboard ? Color.white.opacity(0.18) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        engine.activeModalTab = .analytics
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 11))
                            Text("Analytics")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(engine.activeModalTab == .analytics ? .white : .gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(engine.activeModalTab == .analytics ? Color.white.opacity(0.18) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)

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
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Divider()
                    .background(Color.gray.opacity(0.4))

                // Tab Content
                if engine.activeModalTab == .leaderboard {
                    leaderboardContent
                } else {
                    AnalyticsDashboardView(analytics: history.analytics, engine: engine)
                }

                Divider()
                    .background(Color.gray.opacity(0.4))

                // Footer
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
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
            .frame(width: 278)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#151515"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(radius: 20)
        }
    }

    // MARK: - Leaderboard Tab Content
    private var leaderboardContent: some View {
        VStack(spacing: 8) {
            // Live Time Pill (Total app time & current run)
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 10))
                    Text("Total:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    Text(formatTime(history.totalPlayTime))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                Text("•")
                    .foregroundColor(.gray.opacity(0.4))

                HStack(spacing: 4) {
                    Text("Run:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    Text(engine.formattedRunTime)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )

            if history.entries.isEmpty && !isCurrentRunBest {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                    Text("No scores recorded yet")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text("Play a game and set your first record!")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .frame(height: 270)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        // Current live run highlighted at #1 if it's the personal best
                        if isCurrentRunBest {
                            HStack {
                                HStack(spacing: 3) {
                                    Text("#1")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.yellow)
                                    Text("LIVE")
                                        .font(.system(size: 7.5, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 3)
                                        .padding(.vertical, 1)
                                        .background(Capsule().fill(Color.yellow))
                                }
                                .frame(width: 44, alignment: .leading)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(engine.score)")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.yellow)
                                    HStack(spacing: 4) {
                                        Text("\(engine.linesCleared) lines")
                                        Text("•")
                                        Text("⏱ \(engine.formattedRunTime)")
                                        Text("•")
                                        Text("In Progress")
                                    }
                                    .font(.system(size: 9))
                                    .foregroundColor(.yellow.opacity(0.85))
                                }

                                Spacer()

                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.yellow.opacity(0.18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                                    )
                            )
                        }

                        ForEach(Array(history.entries.enumerated()), id: \.element.id) { index, entry in
                            let rank = isCurrentRunBest ? index + 2 : index + 1
                            HStack {
                                Text("#\(rank)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(rankColor(rank - 1))
                                    .frame(width: 26, alignment: .leading)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(entry.score)")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    HStack(spacing: 4) {
                                        Text("\(entry.lines) lines")
                                        Text("•")
                                        Text("⏱ \(entry.formattedDuration)")
                                        Text("•")
                                        Text(entry.formattedDate)
                                    }
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                                }

                                Spacer()

                                if rank == 1 {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(rank == 1 ? Color.yellow.opacity(0.12) : Color.white.opacity(0.06))
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(maxHeight: 290)
            }
        }
    }

    private var isCurrentRunBest: Bool {
        guard !engine.isDead && engine.score > 0 else { return false }
        let topScore = history.entries.first?.score ?? 0
        return engine.score >= topScore
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

// MARK: - Analytics Dashboard View
struct AnalyticsDashboardView: View {
    let analytics: GameAnalytics
    @ObservedObject var engine: GameEngine

    private var isCurrentRunBest: Bool {
        guard !engine.isDead && engine.score > 0 else { return false }
        let topScore = ScoreHistoryManager.shared.entries.first?.score ?? 0
        return engine.score >= topScore
    }

    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 12) {
                // Top Highlight if current run is your best run!
                if isCurrentRunBest {
                    currentRunBestBanner
                }

                // 1. Archetype Banner
                archetypeBanner

                // 2. Time & Endurance Section
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "TIME & ENDURANCE", icon: "clock.fill", color: .cyan)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        AnalyticsMetricTile(
                            title: "Total Play Time",
                            value: formatTime(analytics.totalPlayTime),
                            subtitle: "Active in-app play",
                            icon: "hourglass",
                            iconColor: .cyan
                        )

                        AnalyticsMetricTile(
                            title: "Longest Run",
                            value: formatTime(max(analytics.longestRunDuration, engine.currentRunTime)),
                            subtitle: "Survival record",
                            icon: "crown.fill",
                            iconColor: .yellow
                        )

                        AnalyticsMetricTile(
                            title: "Average Run",
                            value: formatTime(analytics.averageRunDuration),
                            subtitle: "\(analytics.totalGamesPlayed) runs logged",
                            icon: "timer",
                            iconColor: .green
                        )

                        AnalyticsMetricTile(
                            title: "Danger Zone",
                            value: formatTime(analytics.dangerZoneSurvivalTime),
                            subtitle: "Stack at row ≤ 6",
                            icon: "flame.fill",
                            iconColor: Color(hex: "#FF0D72")
                        )
                    }
                }

                // 3. Speed & Pacing Section
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "SPEED & EFFICIENCY", icon: "bolt.fill", color: .yellow)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        AnalyticsMetricTile(
                            title: "Pieces / Min",
                            value: String(format: "%.1f", analytics.piecesPerMinute),
                            subtitle: "Drop speed rate",
                            icon: "speedometer",
                            iconColor: .orange
                        )

                        AnalyticsMetricTile(
                            title: "Score / Min",
                            value: String(format: "%.0f", analytics.scorePerMinute),
                            subtitle: "Points efficiency",
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: .purple
                        )

                        AnalyticsMetricTile(
                            title: "Total Blocks",
                            value: "\(analytics.totalPiecesPlaced)",
                            subtitle: "Placed & locked",
                            icon: "square.grid.3x3.fill",
                            iconColor: .blue
                        )

                        AnalyticsMetricTile(
                            title: "Avg Score / Run",
                            value: "\(analytics.averageScore)",
                            subtitle: "Per-game points",
                            icon: "target",
                            iconColor: .mint
                        )
                    }
                }

                // 4. Tetris Rate & Clear Breakdown
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "LINE CLEAR MASTERY", icon: "sparkles", color: Color(hex: "#F538FF"))

                    // Tetris Rate Card with progress bar
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tetris Rate")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Lines from 4-line Tetrises")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text(String(format: "%.1f%%", analytics.tetrisRate))
                                .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color(hex: "#F538FF"))
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#0DC2FF"), Color(hex: "#F538FF")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(analytics.tetrisRate / 100.0))), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                    )

                    // Breakdown Rows
                    VStack(spacing: 4) {
                        clearBreakdownRow(name: "Tetris (4 lines)", count: analytics.tetrisCount, color: Color(hex: "#F538FF"), pts: "+609 ea")
                        clearBreakdownRow(name: "Triple (3 lines)", count: analytics.triplesCount, color: Color(hex: "#3877FF"), pts: "+356 ea")
                        clearBreakdownRow(name: "Double (2 lines)", count: analytics.doublesCount, color: Color(hex: "#0DFF72"), pts: "+188 ea")
                        clearBreakdownRow(name: "Single (1 line)", count: analytics.singlesCount, color: Color(hex: "#FF8E0D"), pts: "+75 ea")
                    }
                }

                // 5. Playstyle: Hard Drop Slammer vs Soft Drop
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "DROP AGGRESSION", icon: "arrow.down.to.line.compact", color: Color(hex: "#0DC2FF"))

                    VStack(spacing: 6) {
                        HStack {
                            Text("Hard Drops (Spacebar)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(analytics.hardDropCount) (\(String(format: "%.0f%%", analytics.hardDropPercentage)))")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#0DC2FF"))
                        }

                        HStack {
                            Text("Total Rows Slammed")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(analytics.hardDropTotalRows) rows")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                    )
                }

                // 6. Tetromino Distribution & Favorite Piece
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "PIECE RADAR", icon: "square.fill.on.square.fill", color: .mint)

                    if let favIdx = analytics.favoritePieceIndex,
                       let favType = TetrominoType(rawValue: favIdx) {
                        HStack(spacing: 10) {
                            Text(favType.name)
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(favType.color)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(favType.color.opacity(0.2))
                                )

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Most Placed: \(favType.name)-Piece")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                Text("\(analytics.pieceCounts[favIdx]) times dropped")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.06))
                        )
                    }

                    // 7 piece mini bars
                    VStack(spacing: 4) {
                        ForEach(TetrominoType.allCases, id: \.rawValue) { piece in
                            let count = analytics.pieceCounts.indices.contains(piece.rawValue) ? analytics.pieceCounts[piece.rawValue] : 0
                            let pct = analytics.totalPiecesPlaced > 0 ? Double(count) / Double(analytics.totalPiecesPlaced) * 100.0 : 0

                            HStack(spacing: 6) {
                                Text(piece.name)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(piece.color)
                                    .frame(width: 14, alignment: .leading)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.08))
                                            .frame(height: 5)
                                        Capsule()
                                            .fill(piece.color)
                                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(pct / 100.0))), height: 5)
                                    }
                                }
                                .frame(height: 5)

                                Text("\(count)")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .frame(width: 30, alignment: .trailing)
                            }
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.04))
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 320)
    }

    // MARK: - Subviews
    private var currentRunBestBanner: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("CURRENT RUN IS YOUR BEST RUN!")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                    Text("LIVE")
                        .font(.system(size: 7.5, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.yellow))
                }

                Text("Score: \(engine.score) • \(engine.linesCleared) lines • ⏱ \(engine.formattedRunTime)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.95))
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.45), lineWidth: 1)
                )
        )
    }

    private var archetypeBanner: some View {
        let arch = analytics.archetype
        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: arch.color).opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: arch.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: arch.color))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(arch.title.uppercased())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(arch.subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: arch.color).opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(.gray)
        }
        .padding(.top, 4)
    }

    private func clearBreakdownRow(name: String, count: Int, color: Color, pts: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
            Text(pts)
                .font(.system(size: 8.5))
                .foregroundColor(.gray.opacity(0.7))
            Spacer()
            Text("\(count)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - Metric Tile Subview
struct AnalyticsMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.system(size: 8))
                .foregroundColor(.gray.opacity(0.7))
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.06))
        )
    }
}
