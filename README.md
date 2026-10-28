# Stacker - Falling Tetra Blocks (macOS)

A native macOS floating menu bar recreation of the popular browser puzzle game **Stacker - Falling Tetra Blocks**, matching the authentic visuals, exact scoring formulas, persistent game state, and local high score history.

---

## ✨ Features

- **Menu Bar Icon & Floating Popup**:
  - Sits in the top macOS menu bar with a custom Tetris icon.
  - Clicking the icon toggles the game window directly underneath.
  - **Always on top**: Floats above all other applications (`NSWindow.Level.floating`).
  - **Auto-Pause on Blur**: Clicking outside the app or switching apps automatically pauses the game.
  - **Draggable**: Drag anywhere on screen by clicking and dragging the window.

- **Strict Grid Alignment & Boundaries**:
  - The falling piece is strictly locked to discrete grid columns.
  - Under no circumstances can blocks ever extend outside the screen boundaries.
  - Subtle background grid guides clearly illustrate the grid structure.
  - Faint **ghost piece projection** displays the exact landing position at the bottom.

- **Linear, Reliable Flips (Rotations)**:
  - Clean, linear 90° rotations using standard 4-state rotation models.
  - Wall-kick system prevents rotations from clipping through walls or colliding with settled blocks.

- **Hard Drop (Spacebar)**:
  - Pressing **Spacebar** instantly hard-drops the tetromino to the bottom, locks it in place, checks for line clears, and awards bonus points.

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

- **Local High Score History**:
  - Saved locally to `~/Library/Application Support/Stacker/scores.json`.
  - Click on **"High score: ..."** or **"🏆 Scores"** to view the Top 50 leaderboard with dates and lines cleared.

---

## 🎮 Controls

| Action | Primary Key | Secondary Key |
| :--- | :--- | :--- |
| **Move Left** | `Left Arrow` | `A` |
| **Move Right** | `Right Arrow` | `D` |
| **Soft Drop** | `Down Arrow` | `S` |
| **Hard Drop (Instant Bottom)** | `Spacebar` | — |
| **Rotate Clockwise** | `Up Arrow` | `W` or `E` |
| **Rotate Counter-Clockwise** | `Q` | — |
| **Pause / Resume** | `P` | Click `❚❚` / `▶` |
| **Restart Game** | `R` | Click `⟲` button |
| **Close / Hide Popup** | `Escape` | Click Menu Bar icon |

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
