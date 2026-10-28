import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingGamePanel!
    private let engine = GameEngine()
    private var keyMonitor: Any?
    private var globalClickMonitor: Any?
    private var isUserRepositioned = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        setupKeyMonitor()
        setupAutoPauseObservers()

        // Automatically show the popup on initial launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showPanel()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.saveCurrentState()
    }

    func applicationDidResignActive(_ notification: Notification) {
        engine.autoPause()
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

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.isUserRepositioned = true
        }

        // Auto pause on window resign key (clicking outside)
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.engine.autoPause()
        }
    }

    // Auto-pause when user clicks outside anywhere on screen
    private func setupAutoPauseObservers() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.panel.isVisible else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !self.panel.frame.contains(mouseLocation) {
                DispatchQueue.main.async {
                    self.engine.autoPause()
                }
            }
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

            x = max(screen.visibleFrame.minX + 8, min(x, screen.visibleFrame.maxX - panelWidth - 8))
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        engine.autoPause()
        panel.orderOut(nil)
    }

    // MARK: - Keyboard Monitoring
    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.panel.isVisible else { return event }

            let isDown = event.type == .keyDown

            switch event.keyCode {
            // Left Arrow (123) / 'A' (0): Discrete grid step left
            case 123, 0:
                if isDown {
                    self.engine.moveLeft()
                }
                return nil

            // Right Arrow (124) / 'D' (2): Discrete grid step right
            case 124, 2:
                if isDown {
                    self.engine.moveRight()
                }
                return nil

            // Down Arrow (125) / 'S' (1): Soft Drop
            case 125, 1:
                self.engine.setSoftDropping(isDown)
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

            // Spacebar (49): Hard Drop automatically to the bottom
            case 49:
                if isDown {
                    self.engine.hardDrop()
                }
                return nil

            // 'P' (35): Toggle Pause
            case 35:
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
        let image = NSImage(size: size, flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

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

        image.isTemplate = true
        return image
    }
}
