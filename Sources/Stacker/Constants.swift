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

    // Colors matching Stacker / Tetrium exact hex codes:
    // T: #FF0D72
    // O: #0DC2FF
    // I: #0DFF72
    // L: #F538FF
    // J: #FF8E0D
    // S: #FFE138
    // Z: #3877FF
    var hexColor: String {
        switch self {
        case .t: return "#FF0D72"
        case .o: return "#0DC2FF"
        case .i: return "#0DFF72"
        case .l: return "#F538FF"
        case .j: return "#FF8E0D"
        case .s: return "#FFE138"
        case .z: return "#3877FF"
        }
    }

    var colorIndex: Int {
        rawValue + 1
    }

    var color: Color {
        Color(hex: hexColor)
    }

    var matrix: [[Int]] {
        switch self {
        case .t:
            return [
                [1, 1, 1],
                [0, 1, 0],
                [0, 0, 0]
            ]
        case .o:
            return [
                [1, 1],
                [1, 1]
            ]
        case .i:
            return [
                [0, 0, 1, 0],
                [0, 0, 1, 0],
                [0, 0, 1, 0],
                [0, 0, 1, 0]
            ]
        case .l:
            return [
                [0, 1, 0],
                [0, 1, 0],
                [0, 1, 1]
            ]
        case .j:
            return [
                [0, 1, 0],
                [0, 1, 0],
                [1, 1, 0]
            ]
        case .s:
            return [
                [0, 1, 1],
                [1, 1, 0],
                [0, 0, 0]
            ]
        case .z:
            return [
                [1, 1, 0],
                [0, 1, 1],
                [0, 0, 0]
            ]
        }
    }
}

struct GameConfig {
    static let columns: Int = 10
    static let rows: Int = 18
    static let deathLimitRow: Int = 4 // Rows 0..<4 are above red limit line

    // Logical dimensions for popup window on macOS:
    static let cellSize: Double = 30.0 // 30 pt per cell (60px retina)
    static let gameWidth: Double = Double(columns) * cellSize // 300 pt
    static let gameHeight: Double = Double(rows) * cellSize  // 540 pt
    static let redLineY: Double = Double(deathLimitRow) * cellSize // 120 pt

    // Original Stacker speeds mapped to 60 FPS in 300x540 points:
    // (In original 600x1080 canvas: vSpeed=3, boost=20, hSpeed=16)
    static let verticalSpeed: Double = 1.5
    static let boostSpeed: Double = 10.0
    static let horizontalSpeed: Double = 8.0
    static let rotateDelay: Int = 10 // frames
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

