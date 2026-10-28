# Stacker - Falling Tetra Blocks (macOS)

A native macOS floating menu bar recreation of the popular browser puzzle game **Stacker - Falling Tetra Blocks**, matching the authentic visuals, exact scoring formulas, persistent game state, and local high score history.

---

## ✨ Features

- **Menu Bar Icon & Floating Popup**:
  - Sits in the top macOS menu bar with a custom Tetris icon.
  - Clicking the icon toggles the game window directly underneath.
  - **Always on top**: Floats above all other applications (`NSWindow.Level.floating`).
  - **Auto-Close on Click Outside**: Clicking outside the app or switching to another app automatically pauses and closes the window.
  - **Draggable**: Drag anywhere on screen by clicking and moving the window.

- **Strict Grid Alignment & Visibility**:
  - All 18 rows are completely visible; the bottom row rests flush on top of the footer with zero obstruction.
  - Subtle background grid outlines clearly delineate the 10×18 playing field.
  - Smooth, lag-free key holding (DAS/ARR) glides seamlessly across columns.
  - Controlled, smooth soft drop speed when holding Down / S.

- **Linear, Reliable Flips (Rotations)**:
  - Clean, linear 90° rotations using standard 4-state SRS rotation matrices.
  - Wall-kick system prevents rotations from clipping through walls or colliding with settled blocks.

- **Hard Drop (Spacebar)**:
  - Pressing **Spacebar** instantly hard-drops the tetromino to the bottom and locks it.
  - Pressing **Spacebar** after dying instantly restarts the game!

- **Exact Scoring Formula**:
  - **Piece Placement**: `+10` points for merging a block.
  - **Soft Drop / Boost**: `+1` point per row while holding Down / S.
  - **Hard Drop**: `+2` points per row dropped with Spacebar.
  - **Line Clear Compound Multiplier**:
    - 1 line: `75` points
    - 2 lines: `188` points (`75 * 1.5 + 75 = 187.5`)
    - 3 lines: `356` points (`187.5 * 1.5 + 75 = 356.25`)
    - 4 lines (Tetris): `609` points (`356.25 * 1.5 + 75 = 609.375`)

- **State Persistence (Close & Reopen)**:
  - Game state automatically serializes to `~/Library/Application Support/Stacker/gamestate.json`.
  - Remembers the exact board matrix, current falling piece position, current rotation, upcoming piece, score, and high score.
  - Reopens in paused state so you never lose a block unexpectedly.

- **Local High Score History & Deep Analytics Dashboard**:
  - Saved locally to `~/Library/Application Support/Stacker/scores.json`.
  - Accessible via **"🏆 Scores"** and **"📊 Stats"** buttons in the footer with tabbed navigation:
    - **Leaderboard Tab**: Top 50 scores with lines cleared, active run durations, and timestamps.
    - **Analytics Tab**: Deep performance telemetry and insights:
      - **Player Archetype System**: Dynamic algorithmic titles (*Speed Demon*, *Danger Walker*, *Tetris Architect*, *Endurance Titan*, *Tactical Stacker*).
      - **Time & Endurance**: All-time active play time, longest survival record, average run length, and **Danger Zone Survival Time** (time spent surviving with the stack near the ceiling line).
      - **Speed & Pacing**: Pieces Per Minute (PPM), Score Per Minute (SPM), and average score per run.
      - **Line Clear Mastery**: Visual **Tetris Rate** meter (% of lines cleared from 4-line quad clears) and clear distributions.
      - **Drop Aggression**: Hard drops vs soft drops ratio, and total distance slammed down.
      - **Piece Radar**: 7-bag tetromino placement distribution and favorite/most dropped piece.
  - Active time tracking **strictly counts active gameplay only** (freezes while paused, dead, or backgrounded).

---

## 🎮 Controls

| Action | Primary Key | Secondary Key |
| :--- | :--- | :--- |
| **Move Left** | `Left Arrow` | `A` (Hold to glide smoothly) |
| **Move Right** | `Right Arrow` | `D` (Hold to glide smoothly) |
| **Soft Drop** | `Down Arrow` | `S` (Smooth controlled fall) |
| **Hard Drop (Play)** | `Spacebar` | — |
| **Restart (After Dying)** | `Spacebar` | Click anywhere |
| **Rotate Clockwise** | `Up Arrow` | `W` or `E` |
| **Rotate Counter-Clockwise** | `Q` | — |
| **Pause / Resume** | `P` | Click `❚❚` / `▶` |
| **Close / Hide Popup** | `Escape` (Global) / `⌘W` | Click `✕` button on header or click Menu Bar icon |
| **Quit App** | `⌘Q` | Right-click Menu Bar icon → Quit |

---

## 🚀 How to Run

Double-click `Stacker.app` or run from terminal:
```bash
./run.sh
```
Or open directly:
```bash
open Stacker.app
```
