import SwiftUI
import AppKit

enum GameTheme: String, CaseIterable, Identifiable, Codable {
    case neon = "Neon Cyberpunk"
    case retro = "Retro Arcade"
    case nordic = "Nordic Pastel"
    case gameboy = "Game Boy 1989"
    case monochrome = "Monochrome Minimal"
    case synthwave = "Synthwave / Dracula"
    case sunset = "Sunset Horizon"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .neon:
            return "Authentic vivid neon on pitch black"
        case .retro:
            return "Classic 80s arcade NES palette"
        case .nordic:
            return "Soft matte pastels, easy on the eyes"
        case .gameboy:
            return "Nostalgic 4-shade greenish LCD"
        case .monochrome:
            return "Clean Apple minimal grayscale"
        case .synthwave:
            return "Midnight purple & electric glow"
        case .sunset:
            return "Warm dusk amber, coral & violet"
        }
    }

    var icon: String {
        switch self {
        case .neon: return "bolt.fill"
        case .retro: return "gamecontroller.fill"
        case .nordic: return "leaf.fill"
        case .gameboy: return "tv.fill"
        case .monochrome: return "circle.lefthalf.filled"
        case .synthwave: return "sparkles"
        case .sunset: return "sun.max.fill"
        }
    }

    // 7 colors for pieces in order: [0: T, 1: O, 2: I, 3: L, 4: J, 5: S, 6: Z]
    var paletteHex: [String] {
        switch self {
        case .neon:
            return [
                "#FF0D72", // T: Hot Pink
                "#0DC2FF", // O: Cyan
                "#0DFF72", // I: Neon Green
                "#F538FF", // L: Magenta
                "#FF8E0D", // J: Orange
                "#FFE138", // S: Yellow
                "#3877FF"  // Z: Royal Blue
            ]
        case .retro:
            return [
                "#9B51E0", // T: Purple
                "#2F80ED", // O: Classic Blue
                "#EB5757", // I: Pure Red
                "#00FFFF", // L: Cyan
                "#F2994A", // J: Orange
                "#219653", // S: Green
                "#F2C94C"  // Z: Yellow
            ]
        case .nordic:
            return [
                "#E06C75", // T: Dusty Rose
                "#61AFEF", // O: Soft Sky
                "#98C379", // I: Sage Mint
                "#C678DD", // L: Lilac
                "#D19A66", // J: Coral
                "#E5C07B", // S: Buttercream
                "#56B6C2"  // Z: Slate Cyan
            ]
        case .gameboy:
            return [
                "#306230", // T: Deep Olive
                "#8BAC0F", // O: Classic Pea Green
                "#9BBC0F", // I: Bright Pistachio
                "#306230", // L: Deep Olive
                "#4D7C0F", // J: Forest Moss
                "#8BAC0F", // S: Pea Green
                "#4D7C0F"  // Z: Forest Moss
            ]
        case .monochrome:
            return [
                "#E0E0E0", // T: Platinum White
                "#BDBDBD", // O: Bright Silver
                "#FFFFFF", // I: Pure White
                "#9E9E9E", // L: Cool Gray
                "#757575", // J: Slate Gray
                "#EEEEEE", // S: Soft White
                "#616161"  // Z: Deep Slate
            ]
        case .synthwave:
            return [
                "#FF79C6", // T: Pink
                "#8BE9FD", // O: Cyan
                "#50FA7B", // I: Spring Green
                "#BD93F9", // L: Lavender Purple
                "#FFB86C", // J: Neon Peach
                "#F1FA8C", // S: Lemon
                "#6272A4"  // Z: Midnight Blue
            ]
        case .sunset:
            return [
                "#FF4B72", // T: Crimson
                "#FF8552", // O: Mango
                "#FFD07B", // I: Golden Yellow
                "#934896", // L: Deep Orchid
                "#F76A8C", // J: Watermelon
                "#F8A978", // S: Peach
                "#574B90"  // Z: Twilight Purple
            ]
        }
    }

    func hexColor(for index: Int) -> String {
        let palette = paletteHex
        guard index >= 0 && index < palette.count else { return "#FFFFFF" }
        return palette[index]
    }

    func color(for index: Int) -> Color {
        Color(hex: hexColor(for: index))
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: GameTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "stacker_theme")
        }
    }

    @Published var paneOpacity: Double {
        didSet {
            UserDefaults.standard.set(paneOpacity, forKey: "stacker_opacity")
            AppDelegate.shared?.updatePanelOpacity(paneOpacity)
        }
    }

    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "stacker_theme"),
           let theme = GameTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .neon
        }

        let savedOpacity = UserDefaults.standard.double(forKey: "stacker_opacity")
        self.paneOpacity = savedOpacity > 0 ? savedOpacity : 1.0
    }

    func color(forPieceIndex index: Int) -> Color {
        currentTheme.color(for: index)
    }

    func color(forBlockIndex blockVal: Int) -> Color {
        guard blockVal > 0 else { return .clear }
        return currentTheme.color(for: blockVal - 1)
    }

    func hexColor(forPieceIndex index: Int) -> String {
        currentTheme.hexColor(for: index)
    }

    func color(forType type: TetrominoType) -> Color {
        color(forPieceIndex: type.rawValue)
    }
}
