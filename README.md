# Stacker - Falling Tetra Blocks (macOS)

A native macOS floating menu bar recreation of the popular browser puzzle game **Stacker - Falling Tetra Blocks**, matching the authentic visuals, smooth physics, exact scoring formulas, persistent game state, and local high score history.

---

## ✨ Features

- **Menu Bar Icon & Floating Popup**:
  - Sits neatly in the top macOS menu bar with a custom Tetris icon.
  - Clicking the icon pops up the game window directly underneath.
  - **Always on top**: Floats above all other applications and full-screen windows (`NSWindow.Level.floating`).
  - **Draggable**: Drag anywhere on screen by clicking and moving the background.

- **Exact Visuals & Mechanics**:
  - Exact color scheme, typography, and layout from *Stacker*:
    - **T-piece**: `#FF0D72` (Hot Pink)
    - **O-piece**: `#0DC2FF` (Cyan)
    - **I-piece**: `#0DFF72` (Neon Green)
    - **L-piece**: `#F538FF` (Magenta)
    - **J-piece**: `#FF8E0D` (Orange)
    - **S-piece**: `#FFE138` (Yellow)
    - **Z-piece**: `#3877FF` (Royal Blue)
  - Solid, flat, borderless tetromino blocks.
  - Smooth tile sliding (`easeTo`) and smooth rotation interpolation.
  - Smooth animated collapse when lines are cleared.
  - Red ceiling limit line at Row 4.
  - Large centered bold score display.
  - "You died" game over notification when blocks cross the red line.

- **Next Piece Indicator**:
  - Integrated directly at the very top of the header bar, previewing the upcoming tetromino with its exact shape and color.

- **Exact Scoring Formula**:
  - **Piece Lock**: `+10` points for merging a block.
  - **Soft Drop / Boost**: `+1` point per row while holding Down / S.
  - **Line Clear Multiplier**:
    - 1 line: `75` points
    - 2 lines: `188` points (`75 * 1.5 + 75 = 187.5`)
    - 3 lines: `356` points (`187.5 * 1.5 + 75 = 356.25`)
    - 4 lines (Tetris): `609` points (`356.25 * 1.5 + 75 = 609.375`)

- **State Persistence (Close & Reopen)**:
  - Game state automatically serializes to `~/Library/Application Support/Stacker/gamestate.json`.
  - Remembers the exact board matrix, current falling piece position, current rotation, upcoming piece, score, and high score.
  - When reopened, restores seamlessly and opens in paused mode so you never lose a block unexpectedly.

- **Local High Score History**:
  - High scores saved locally to `~/Library/Application Support/Stacker/scores.json`.
  - Click on **"High score: ..."** or **"🏆 Scores"** to view the Top 50 leaderboard with dates and lines cleared.

---

## 🎮 Controls

| Action | Primary Key | Secondary Key |
| :--- | :--- | :--- |
| **Move Left** | `Left Arrow` | `A` |
| **Move Right** | `Right Arrow` | `D` |
| **Soft Drop (Boost)** | `Down Arrow` | `S` |
| **Rotate Clockwise** | `Up Arrow` | `W` or `E` |
| **Rotate Counter-Clockwise** | `Q` | — |
| **Pause / Resume** | `Spacebar` | Click `❚❚` / `▶` |
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

