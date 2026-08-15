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
}
