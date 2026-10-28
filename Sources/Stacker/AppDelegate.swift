import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private var statusItem: NSStatusItem!
    private var panel: FloatingGamePanel!
    private let engine = GameEngine()
    private var keyMonitor: Any?
    private var globalClickMonitor: Any?
    private var globalKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupStatusItem()
        setupPanel()
        setupKeyMonitor()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showPanel()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.saveCurrentState()
        ScoreHistoryManager.shared.save()
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

    @objc func quitApp() {
        engine.saveCurrentState()
        ScoreHistoryManager.shared.save()
        NSApp.terminate(nil)
    }

    // MARK: - Floating Panel Setup
    private func setupPanel() {
        let width = GameConfig.gameWidth
        let height = GameConfig.totalHeight
        let rect = NSRect(x: 0, y: 0, width: width, height: height)

        panel = FloatingGamePanel(contentRect: rect)

        let hostingView = NSHostingView(rootView: GameView(engine: engine))
        hostingView.frame = rect
        panel.contentView = hostingView

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.engine.autoPause()
        }
    }

    private func setupGlobalMonitors() {
        removeGlobalMonitors()

        // 1. Global click monitor to auto-pause when clicking outside
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.panel.isVisible else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !self.panel.frame.contains(mouseLocation) {
                DispatchQueue.main.async {
                    self.engine.autoPause()
                }
            }
        }

        // 2. Global Escape key monitor: hitting Escape ANYWHERE closes Stacker immediately without clicking inside first!
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.panel.isVisible else { return }
            if event.keyCode == 53 { // Escape
                DispatchQueue.main.async {
                    self.hidePanel()
                }
            }
        }
    }

    private func removeGlobalMonitors() {
        if let m = globalClickMonitor {
            NSEvent.removeMonitor(m)
            globalClickMonitor = nil
        }
        if let m = globalKeyMonitor {
            NSEvent.removeMonitor(m)
            globalKeyMonitor = nil
        }
    }

    @objc func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    // Always auto-open in the top right corner of the screen
    func showPanel() {
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let panelWidth = GameConfig.gameWidth
            let panelHeight = GameConfig.totalHeight
            let margin: CGFloat = 12.0

            let x = screen.visibleFrame.maxX - panelWidth - margin
            let y = screen.visibleFrame.maxY - panelHeight - margin

            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if !engine.isPaused && !engine.isDead {
            engine.startLoop()
        }
        setupGlobalMonitors()
    }

    func hidePanel() {
        engine.autoPause()
        engine.stopLoop()
        panel.orderOut(nil)
        removeGlobalMonitors()
    }

    // MARK: - Keyboard Monitoring with Key Hold Support
    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.panel.isVisible else { return event }

            let isDown = event.type == .keyDown

            // Command shortcuts: ⌘W closes window, ⌘Q quits app
            if event.modifierFlags.contains(.command) && isDown {
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "w":
                    self.hidePanel()
                    return nil
                case "q":
                    self.quitApp()
                    return nil
                default:
                    break
                }
            }

            switch event.keyCode {
            // Left Arrow (123) / 'A' (0): Hold to move continuously
            case 123, 0:
                self.engine.setLeftHeld(isDown)
                return nil

            // Right Arrow (124) / 'D' (2): Hold to move continuously
            case 124, 2:
                self.engine.setRightHeld(isDown)
                return nil

            // Down Arrow (125) / 'S' (1): Soft Drop (same smooth speed as horizontal move!)
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

            // Spacebar (49): Unpause when paused, restart when dead, hard drop while playing!
            case 49:
                if isDown {
                    if self.engine.isDead {
                        self.engine.startNewGame()
                    } else if self.engine.isPaused {
                        self.engine.togglePause()
                    } else {
                        self.engine.hardDrop()
                    }
                }
                return nil

            // 'P' (35): Toggle Pause
            case 35:
                if isDown {
                    self.engine.togglePause()
                }
                return nil

            // 'R' (15): Restart game
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
                    self.engine.startNewGame()
                    return nil
                }
                return event
            }
        }
    }

    // MARK: - Tetris Menu Bar Icon
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
