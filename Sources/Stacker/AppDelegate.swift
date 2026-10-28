import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingGamePanel!
    private let engine = GameEngine()
    private var keyMonitor: Any?
    private var isUserRepositioned = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        setupKeyMonitor()

        // Automatically show the popup on initial launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showPanel()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.saveCurrentState()
    }

    func applicationDidResignActive(_ notification: Notification) {
        engine.saveCurrentState()
    }

    // MARK: - Menu Bar Setup
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = createTetrisMenuBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "Stacker - Falling Tetra Blocks"
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Stacker", action: #selector(togglePanel), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "Restart Game", action: #selector(restartGame), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Stacker", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Reset menu back to nil so left clicks work normally
        DispatchQueue.main.async {
            self.statusItem.menu = nil
        }
    }

    @objc private func restartGame() {
        engine.startNewGame()
        if !panel.isVisible {
            showPanel()
        }
    }

    @objc private func quitApp() {
        engine.saveCurrentState()
        NSApp.terminate(nil)
    }

    // MARK: - Floating Panel Setup
    private func setupPanel() {
        let width = GameConfig.gameWidth
        let height = GameConfig.gameHeight
        let rect = NSRect(x: 0, y: 0, width: width, height: height)

        panel = FloatingGamePanel(contentRect: rect)

        let hostingView = NSHostingView(rootView: GameView(engine: engine))
        hostingView.frame = rect
        panel.contentView = hostingView

        // Notification when user moves the panel
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.isUserRepositioned = true
        }
    }

    @objc func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        if !isUserRepositioned, let button = statusItem.button, let screen = button.window?.screen {
            let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
            let panelWidth = GameConfig.gameWidth
            let panelHeight = GameConfig.gameHeight

            var x = buttonFrame.midX - (panelWidth / 2)
            let y = buttonFrame.minY - panelHeight - 6

            // Keep within screen edges
            x = max(screen.visibleFrame.minX + 8, min(x, screen.visibleFrame.maxX - panelWidth - 8))
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        if !engine.isDead && !engine.isPaused {
            engine.togglePause()
        }
        engine.saveCurrentState()
        panel.orderOut(nil)
    }

    // MARK: - Keyboard Monitoring
    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.panel.isVisible else { return event }

            let isDown = event.type == .keyDown

            switch event.keyCode {
            // Left Arrow (123) / 'A' (0)
            case 123, 0:
                self.engine.setLeftPressed(isDown)
                return nil

            // Right Arrow (124) / 'D' (2)
            case 124, 2:
                self.engine.setRightPressed(isDown)
                return nil

            // Down Arrow (125) / 'S' (1)
            case 125, 1:
                self.engine.setDownPressed(isDown)
                return nil

            // Up Arrow (126) / 'W' (13) / 'E' (14): Rotate Clockwise
            case 126, 13, 14:
                if isDown {
                    self.engine.rotate(dir: 1)
                }
                return nil

            // 'Q' (12): Rotate Counter-Clockwise
            case 12:
                if isDown {
                    self.engine.rotate(dir: -1)
                }
                return nil

            // Spacebar (49): Toggle Pause
            case 49:
                if isDown {
                    self.engine.togglePause()
                }
                return nil

            // 'R' (15): Restart
            case 15:
                if isDown {
                    self.engine.startNewGame()
                }
                return nil

            // Escape (53): Close / Hide Panel
            case 53:
                if isDown {
                    self.hidePanel()
                }
                return nil

            default:
                if isDown && self.engine.isDead {
                    // Any key restarts when dead
                    self.engine.startNewGame()
                    return nil
                }
                return event
            }
        }
    }

    // MARK: - Tetris Menu Bar Icon Drawing
    private func createTetrisMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            // Draw a stylish 4-block T-piece icon
            // Top row: 3 blocks, bottom center: 1 block
            let blockSize: CGFloat = 4.5
            let spacing: CGFloat = 1.0
            let startX: CGFloat = (size.width - (blockSize * 3 + spacing * 2)) / 2
            let startY: CGFloat = (size.height - (blockSize * 2 + spacing)) / 2

            context.setFillColor(NSColor.black.cgColor)

            // Top 3 blocks
            for i in 0..<3 {
                let x = startX + CGFloat(i) * (blockSize + spacing)
                let y = startY + blockSize + spacing
                let blockRect = CGRect(x: x, y: y, width: blockSize, height: blockSize)
                context.fill(blockRect)
            }

            // Bottom center block
            let centerX = startX + 1 * (blockSize + spacing)
            let centerY = startY
            let centerRect = CGRect(x: centerX, y: centerY, width: blockSize, height: blockSize)
            context.fill(centerRect)

            return true
        }

        image.isTemplate = true // Seamlessly adapts to macOS light & dark menu bars
        return image
    }
}

