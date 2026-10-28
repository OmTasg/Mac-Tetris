import AppKit

final class FloatingGamePanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.title = "Stacker"
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.hasShadow = true
        self.backgroundColor = .black
        self.isOpaque = false

        // Rounded corners
        if let contentView = self.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

