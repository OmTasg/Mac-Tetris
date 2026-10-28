import SwiftUI

enum TetrominoType: Int, CaseIterable {
    case t = 0
    case o = 1
    case i = 2
    case l = 3
    case j = 4
    case s = 5
    case z = 6

    var name: String {
        switch self {
        case .t: return "T"
        case .o: return "O"
        case .i: return "I"
        case .l: return "L"
        case .j: return "J"
        case .s: return "S"
        case .z: return "Z"
        }
    }

    // Authentic Stacker / Tetrium hex colors
    var hexColor: String {
        switch self {
        case .t: return "#FF0D72" // Hot pink
        case .o: return "#0DC2FF" // Cyan
        case .i: return "#0DFF72" // Neon green
        case .l: return "#F538FF" // Magenta
        case .j: return "#FF8E0D" // Orange
        case .s: return "#FFE138" // Yellow
        case .z: return "#3877FF" // Royal blue
        }
    }

    var colorIndex: Int {
        rawValue + 1
    }

    var color: Color {
        Color(hex: hexColor)
    }

    // All 4 pre-calculated SRS standard rotation states:
    var allRotationStates: [[[Int]]] {
        switch self {
        case .t:
            return [
                [
                    [0, 1, 0],
                    [1, 1, 1],
                    [0, 0, 0]
                ],
                [
                    [0, 1, 0],
                    [0, 1, 1],
                    [0, 1, 0]
                ],
                [
                    [0, 0, 0],
                    [1, 1, 1],
                    [0, 1, 0]
                ],
                [
                    [0, 1, 0],
                    [1, 1, 0],
                    [0, 1, 0]
                ]
            ]

        case .o:
            let oState = [
                [1, 1],
                [1, 1]
            ]
            return [oState, oState, oState, oState]

        case .i:
            return [
                [
                    [0, 0, 0, 0],
                    [1, 1, 1, 1],
                    [0, 0, 0, 0],
                    [0, 0, 0, 0]
                ],
                [
                    [0, 0, 1, 0],
                    [0, 0, 1, 0],
                    [0, 0, 1, 0],
                    [0, 0, 1, 0]
                ],
                [
                    [0, 0, 0, 0],
                    [0, 0, 0, 0],
                    [1, 1, 1, 1],
                    [0, 0, 0, 0]
                ],
                [
                    [0, 1, 0, 0],
                    [0, 1, 0, 0],
                    [0, 1, 0, 0],
                    [0, 1, 0, 0]
                ]
            ]

        case .l:
            return [
                [
                    [0, 0, 1],
                    [1, 1, 1],
                    [0, 0, 0]
                ],
                [
                    [0, 1, 0],
                    [0, 1, 0],
                    [0, 1, 1]
                ],
                [
                    [0, 0, 0],
                    [1, 1, 1],
                    [1, 0, 0]
                ],
                [
                    [1, 1, 0],
                    [0, 1, 0],
                    [0, 1, 0]
                ]
            ]

        case .j:
            return [
                [
                    [1, 0, 0],
                    [1, 1, 1],
                    [0, 0, 0]
                ],
                [
                    [0, 1, 1],
                    [0, 1, 0],
                    [0, 1, 0]
                ],
                [
                    [0, 0, 0],
                    [1, 1, 1],
                    [0, 0, 1]
                ],
                [
                    [0, 1, 0],
                    [0, 1, 0],
                    [1, 1, 0]
                ]
            ]

        case .s:
            return [
                [
                    [0, 1, 1],
                    [1, 1, 0],
                    [0, 0, 0]
                ],
                [
                    [0, 1, 0],
                    [0, 1, 1],
                    [0, 0, 1]
                ],
                [
                    [0, 0, 0],
                    [0, 1, 1],
                    [1, 1, 0]
                ],
                [
                    [1, 0, 0],
                    [1, 1, 0],
                    [0, 1, 0]
                ]
            ]

        case .z:
            return [
                [
                    [1, 1, 0],
                    [0, 1, 1],
                    [0, 0, 0]
                ],
                [
                    [0, 0, 1],
                    [0, 1, 1],
                    [0, 1, 0]
                ],
                [
                    [0, 0, 0],
                    [1, 1, 0],
                    [0, 1, 1]
                ],
                [
                    [0, 1, 0],
                    [1, 1, 0],
                    [1, 0, 0]
                ]
            ]
        }
    }

    var defaultMatrix: [[Int]] {
        allRotationStates[0]
    }
}

struct GameConfig {
    static let columns: Int = 10
    static let rows: Int = 18
    static let deathLimitRow: Int = 4 // Rows 0..<4 are above the red limit line

    // Logical dimensions for popup window on macOS:
    static let cellSize: Double = 30.0 // 30 pt per cell (60px retina)
    static let gameWidth: Double = Double(columns) * cellSize // 300 pt
    static let gameHeight: Double = Double(rows) * cellSize  // 540 pt
    static let redLineY: Double = Double(deathLimitRow) * cellSize // 120 pt

    // Gravity / falling speeds (rows per tick at 60 FPS):
    static let normalFallSpeed: Double = 0.035 // ~28 frames per row
    static let softDropSpeed: Double = 0.35     // ~3 frames per row
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static func fromIndex(_ index: Int) -> Color {
        guard let piece = TetrominoType(rawValue: index - 1) else {
            return .clear
        }
        return piece.color
    }
}
