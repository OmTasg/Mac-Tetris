import Foundation
import SwiftUI

final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    @Published var paneOpacity: Double {
        didSet {
            let clamped = max(0.3, min(1.0, paneOpacity))
            if paneOpacity != clamped {
                paneOpacity = clamped
            }
            UserDefaults.standard.set(paneOpacity, forKey: "stacker_opacity")
            AppDelegate.shared?.updatePanelOpacity(paneOpacity)
        }
    }

    init() {
        let saved = UserDefaults.standard.double(forKey: "stacker_opacity")
        self.paneOpacity = saved > 0 ? saved : 1.0
    }

    var formattedOpacity: String {
        "\(Int(round(paneOpacity * 100)))%"
    }

    // Quick 1-click preset cycle: 100% -> 85% -> 70% -> 50% -> 100%
    func cyclePreset() {
        if paneOpacity >= 0.95 {
            paneOpacity = 0.85
        } else if paneOpacity >= 0.80 {
            paneOpacity = 0.70
        } else if paneOpacity >= 0.65 {
            paneOpacity = 0.50
        } else {
            paneOpacity = 1.0
        }
    }

    // Adjust by 5% steps (keyboard shortcuts '[' / ']')
    func adjust(by delta: Double) {
        let updated = round((paneOpacity + delta) * 20.0) / 20.0
        paneOpacity = max(0.3, min(1.0, updated))
    }
}
