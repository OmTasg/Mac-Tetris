import SwiftUI

struct GameView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 0) {
            // Main Playing Area (Canvas + Header + Ceiling Line)
            ZStack(alignment: .top) {
                // Pure Solid Black Background
                Color.black
                    .ignoresSafeArea()

                // Main Arena Canvas (Exactly 300 x 540 pt)
                Canvas { context, size in
                    let cell = GameConfig.cellSize

                    // 1. Settled Arena Blocks (100% Solid Flat Colors, No Lines or Gaps)
                    for y in 0..<GameConfig.rows {
                        for x in 0..<GameConfig.columns {
                            let val = engine.arena[y][x]
                            if val > 0 {
                                let rect = CGRect(
                                    x: Double(x) * cell,
                                    y: Double(y) * cell,
                                    width: cell,
                                    height: cell
                                )

                                context.fill(
                                    Path(rect),
                                    with: .color(Color.fromIndex(val))
                                )
                            }
                        }
                    }

                    // 2. Active Falling Tetromino (100% Solid Flat Colors, No Lines or Gaps)
                    if !engine.isDead {
                        let shape = engine.currentShape
                        for r in 0..<shape.count {
                            for c in 0..<shape[r].count {
                                if shape[r][c] != 0 {
                                    let rect = CGRect(
                                        x: Double(engine.gridX + c) * cell,
                                        y: Double(engine.gridY + r) * cell,
                                        width: cell,
                                        height: cell
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
                    engine.activeModalTab = .leaderboard
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

                // Paused Badge Overlay (Click anywhere inside canvas or press Space to unpause!)
                if engine.isPaused && !engine.isDead {
                    ZStack {
                        // Full-canvas tap target to unpause immediately when clicking anywhere
                        Color.black.opacity(0.18)

                        VStack(spacing: 8) {
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

                            Text("Click anywhere or Space to Resume")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.top, 6)
                        }
                    }
                    .frame(width: GameConfig.gameWidth, height: GameConfig.gameHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        engine.unpause()
                    }
                }

                // Header UI (Top Controls & Score - No Restart Button)
                VStack(spacing: 2) {
                    HStack(alignment: .center) {
                        // Next Piece Indicator on the top-left
                        NextPieceView(shapeIndex: engine.nextShapeIndex)

                        Spacer()

                        HStack(spacing: 6) {
                            // Pause Button (❚❚ / ▶) on the top-right
                            Button(action: {
                                engine.togglePause()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Pause / Resume (P or Space)")

                            // Close Button (✕)
                            Button(action: {
                                AppDelegate.shared?.hidePanel()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Close Window (Esc or ⌘W)")
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    // Giant Score Display
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
                        Text("Lines: \(engine.linesCleared) • Time: \(engine.formattedRunTime)")
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

                        Button("View Scores & Analytics") {
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

                // High Score History Modal Sheet
                if engine.showHistory {
                    ScoreHistoryView(engine: engine)
                        .transition(.opacity)
                }
            }
            .frame(width: GameConfig.gameWidth, height: GameConfig.gameHeight)

            // Minimal Footer (Below canvas, never overlapping Row 17)
            HStack {
                HStack(spacing: 7) {
                    Button(action: {
                        engine.activeModalTab = .leaderboard
                        engine.showHistory = true
                    }) {
                        Text("🏆 Scores")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        engine.activeModalTab = .analytics
                        engine.showHistory = true
                    }) {
                        Text("📊 Stats")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        engine.activeModalTab = .style
                        engine.showHistory = true
                    }) {
                        Text("🎨 Style")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(engine.formattedRunTime)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.gray.opacity(0.85))

                Spacer()

                Button(action: {
                    AppDelegate.shared?.hidePanel()
                }) {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                        Text("On Top")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(.plain)
                .help("Click to Hide (Esc or ⌘W)")
            }
            .padding(.horizontal, 12)
            .frame(width: GameConfig.gameWidth, height: GameConfig.footerHeight)
            .background(Color(hex: "#111111"))
        }
        .frame(width: GameConfig.gameWidth, height: GameConfig.totalHeight)
        .clipped()
        .animation(.easeInOut(duration: 0.15), value: engine.showHistory)
    }
}
