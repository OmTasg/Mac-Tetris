import SwiftUI

struct GameView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 0) {
            // Main Playing Area (Canvas + Header + Ceiling Line)
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()

                // Main Arena Canvas (Exactly 300 x 540 pt)
                Canvas { context, size in
                    let cell = GameConfig.cellSize

                    // 1. Subtle Grid Outlines (clearly shows every single row 4..<18)
                    for r in GameConfig.deathLimitRow..<GameConfig.rows {
                        for c in 0..<GameConfig.columns {
                            let rect = CGRect(
                                x: Double(c) * cell,
                                y: Double(r) * cell,
                                width: cell,
                                height: cell
                            )
                            context.stroke(
                                Path(rect),
                                with: .color(Color.white.opacity(0.04)),
                                lineWidth: 0.5
                            )
                        }
                    }

                    // 2. Settled Arena Blocks (Row 17 sits right on the floor above footer)
                    for y in 0..<GameConfig.rows {
                        for x in 0..<GameConfig.columns {
                            let val = engine.arena[y][x]
                            if val > 0 {
                                var yOffset = 0.0
                                if let breakRow = engine.lineClearBreakRow, y < breakRow {
                                    yOffset = engine.lineClearOffset
                                }

                                let rect = CGRect(
                                    x: Double(x) * cell + 0.5,
                                    y: Double(y) * cell + yOffset + 0.5,
                                    width: cell - 1.0,
                                    height: cell - 1.0
                                )

                                context.fill(
                                    Path(rect),
                                    with: .color(Color.fromIndex(val))
                                )
                            }
                        }
                    }

                    // 3. Active Falling Tetromino (Strict Grid Placement)
                    if !engine.isDead {
                        let shape = engine.currentShape
                        for r in 0..<shape.count {
                            for c in 0..<shape[r].count {
                                if shape[r][c] != 0 {
                                    let rect = CGRect(
                                        x: Double(engine.gridX + c) * cell + 0.5,
                                        y: Double(engine.gridY + r) * cell + 0.5,
                                        width: cell - 1.0,
                                        height: cell - 1.0
                                    )
                                    context.fill(
                                        Path(rect),
                                        with: .color(engine.currentColor)
                                    )
                                }
                            }
                        }
                    }
                }
                .frame(width: GameConfig.gameWidth, height: GameConfig.gameHeight)

                // Red Ceiling Line at Row 4
                Rectangle()
                    .fill(Color.red)
                    .frame(width: GameConfig.gameWidth, height: 1.5)
                    .offset(y: GameConfig.redLineY)

                // High Score Text centered directly below red line
                Button(action: {
                    engine.showHistory = true
                }) {
                    HStack(spacing: 4) {
                        Text("High score: \(engine.highscore)")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
                .offset(y: GameConfig.redLineY + 12)

                // Header UI (Top Controls & Score - No Restart Button)
                VStack(spacing: 2) {
                    HStack(alignment: .center) {
                        // Next Piece Indicator on the top-left
                        NextPieceView(shapeIndex: engine.nextShapeIndex)

                        Spacer()

                        // Pause Button (❚❚ / ▶) on the top-right
                        Button(action: {
                            engine.togglePause()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 36, height: 36)
                                Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Pause / Resume (P)")
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    // Giant Score Display (Exact Stacker visual)
                    Text("\(engine.score)")
                        .font(.system(size: 44, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.top, 2)
                }
                .frame(width: GameConfig.gameWidth)

                // "You died" Game Over Overlay (Spacebar restarts)
                if engine.isDead {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 200)
                        Text("You died")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.red)
                        Text("Final Score: \(engine.score)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Lines: \(engine.linesCleared)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)

                        Text("Press Space to Restart")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.top, 6)

                        Button("View High Scores") {
                            engine.showHistory = true
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                        .buttonStyle(.plain)
                    }
                    .frame(width: GameConfig.gameWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        engine.startNewGame()
                    }
                }

                // Paused Badge Overlay
                if engine.isPaused && !engine.isDead {
                    VStack {
                        Spacer().frame(height: 240)
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 22))
                            Text("PAUSED")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        Text("Press P or click Play to Resume")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.top, 6)
                    }
                    .frame(width: GameConfig.gameWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        engine.togglePause()
                    }
                }

                // High Score History Modal Sheet
                if engine.showHistory {
                    ScoreHistoryView(engine: engine)
                        .transition(.opacity)
                }
            }
            .frame(width: GameConfig.gameWidth, height: GameConfig.gameHeight)

            // Minimal Footer (Placed below canvas, NEVER overlapping Row 17!)
            HStack {
                Button(action: {
                    engine.showHistory = true
                }) {
                    Text("🏆 Scores")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Space: Drop • Hold: Move • P: Pause")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.7))

                Spacer()

                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                    Text("On Top")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 14)
            .frame(width: GameConfig.gameWidth, height: GameConfig.footerHeight)
            .background(Color(hex: "#111111"))
        }
        .frame(width: GameConfig.gameWidth, height: GameConfig.totalHeight)
        .clipped()
        .animation(.easeInOut(duration: 0.15), value: engine.showHistory)
    }
}
