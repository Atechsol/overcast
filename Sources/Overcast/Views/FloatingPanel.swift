import AppKit

/// A borderless, non-activating panel that floats above normal windows,
/// follows you across Spaces/full-screen apps, and never steals keyboard focus.
final class FloatingPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        isOpaque = false
        backgroundColor = .clear
        // AppKit's native window shadow traces the clear window's alpha silhouette,
        // which renders as a coarse hexagonal artifact around small rounded content.
        // The SwiftUI-level .shadow() in OvercastView draws the real shadow instead.
        hasShadow = false

        isMovableByWindowBackground = true
        hidesOnDeactivate = false

        // Keep it visible even when other apps are focused.
        becomesKeyOnlyIfNeeded = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // NSHostingView's SwiftUI content swallows rightMouseDown before AppKit's
    // default "show contentView.menu" handling ever runs, so a right-click
    // never reached it. Pop the menu directly at the window level instead.
    override func rightMouseDown(with event: NSEvent) {
        guard let contentView, let menu = contentView.menu else {
            super.rightMouseDown(with: event)
            return
        }
        NSMenu.popUpContextMenu(menu, with: event, for: contentView)
    }
}
