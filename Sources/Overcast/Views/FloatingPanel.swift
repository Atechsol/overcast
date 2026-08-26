import AppKit

/// A borderless, non-activating panel that floats above normal windows,
/// follows you across Spaces/full-screen apps, and never steals keyboard focus.
final class FloatingPanel: NSPanel {
    /// Called once a drag ends (mouseUp), so the caller can check whether to
    /// dock/undock. isMovableByWindowBackground's built-in dragging runs its
    /// own internal event-tracking loop that a normal NSEvent monitor can't
    /// reliably observe the end of, so dragging is implemented manually here
    /// instead, giving us a guaranteed drag-end callback.
    var onDragEnd: (() -> Void)?

    private var dragStartMouseLocation: NSPoint?
    private var dragStartWindowOrigin: NSPoint?

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

        isMovableByWindowBackground = false // dragging handled manually below
        hidesOnDeactivate = false

        // Keep it visible even when other apps are focused.
        becomesKeyOnlyIfNeeded = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func mouseDown(with event: NSEvent) {
        dragStartMouseLocation = NSEvent.mouseLocation
        dragStartWindowOrigin = frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startMouse = dragStartMouseLocation, let startOrigin = dragStartWindowOrigin else { return }
        let current = NSEvent.mouseLocation
        let target = NSPoint(
            x: startOrigin.x + (current.x - startMouse.x),
            y: startOrigin.y + (current.y - startMouse.y)
        )
        setFrameOrigin(Self.clampToDesktopBounds(origin: target, size: frame.size))
    }

    /// Keeps the panel's origin within the union of every connected screen's
    /// frame, so dragging can't push it past the outer edge into empty space
    /// where it'd be stuck out of reach.
    private static func clampToDesktopBounds(origin: NSPoint, size: NSSize) -> NSPoint {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return origin }
        let minX = screens.map { $0.frame.minX }.min() ?? origin.x
        let maxX = screens.map { $0.frame.maxX }.max() ?? origin.x
        let minY = screens.map { $0.frame.minY }.min() ?? origin.y
        let maxY = screens.map { $0.frame.maxY }.max() ?? origin.y
        return NSPoint(
            x: min(max(origin.x, minX), maxX - size.width),
            y: min(max(origin.y, minY), maxY - size.height)
        )
    }

    override func mouseUp(with event: NSEvent) {
        let wasDragging = dragStartMouseLocation != nil
        dragStartMouseLocation = nil
        dragStartWindowOrigin = nil
        if wasDragging {
            onDragEnd?()
        }
    }

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
