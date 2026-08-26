import SwiftUI
import AppKit

// Entry point for a menubar-less, dock-less floating companion app.
// We use NSApplicationDelegate directly (not the SwiftUI App lifecycle)
// so we have full control over the NSPanel window and can keep this
// out of the Dock / Cmd-Tab switcher.

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel!
    var settingsWindow: NSWindow?
    var weatherService = WeatherService()
    var moodManager = MoodManager()
    var dockState = PanelDockState()
    var eventListener: EventListener?

    static let defaultPanelOrigin = NSPoint(x: 100, y: 100)
    static let floatingSize = NSSize(width: 210, height: 210)
    static let dockedSize = NSSize(width: 90, height: 230)
    static let dockThreshold: CGFloat = 24
    static let undockThreshold: CGFloat = 40

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock + Cmd-Tab: this is a background utility, not a regular app.
        NSApp.setActivationPolicy(.accessory)

        let contentView = OvercastView()
            .environmentObject(weatherService)
            .environmentObject(moodManager)
            .environmentObject(dockState)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.sizingOptions = [.preferredContentSize]

        let config = AppConfig.load()
        let (origin, size) = Self.restoredFrame(from: config)
        if let rawEdge = config?.dockedEdge, let edge = DockedEdge(rawValue: rawEdge) {
            dockState.edge = edge
        }

        panel = FloatingPanel(contentRect: NSRect(origin: origin, size: size))
        panel.contentView = hostingView
        panel.alphaValue = config?.opacity.map { CGFloat($0) } ?? 1.0
        panel.onDragEnd = { [weak self] in self?.checkDockSnap() }
        panel.makeKeyAndOrderFront(nil)

        refreshContextMenu()

        weatherService.start()
        moodManager.startAutoRotate()

        eventListener = EventListener { [weak self] event in
            self?.moodManager.trigger(event)
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [self] in
                self.savePanelPosition()
            }
        }

        // LSUIElement hides the menu bar entirely, so there's no Application
        // menu to catch Cmd+Q — intercept it manually instead.
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "q" {
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }

    /// Resolves the launch frame: docked (flush against the saved edge, using
    /// the current screen arrangement's outer bounds — this machine's monitor
    /// layout may differ from whenever the position was last saved) or floating
    /// at the saved/default position.
    private static func restoredFrame(from config: AppConfig?) -> (origin: NSPoint, size: NSSize) {
        if let rawEdge = config?.dockedEdge, let edge = DockedEdge(rawValue: rawEdge) {
            let y = config?.panelY ?? Double(defaultPanelOrigin.y)
            let x = edge == .left ? outerLeftX() : outerRightX() - Double(dockedSize.width)
            return (NSPoint(x: x, y: y), dockedSize)
        }
        let savedOrigin = NSPoint(x: config?.panelX ?? Double(defaultPanelOrigin.x),
                                   y: config?.panelY ?? Double(defaultPanelOrigin.y))
        return (clamp(origin: savedOrigin, size: floatingSize), floatingSize)
    }

    private static func outerLeftX() -> Double {
        Double(NSScreen.screens.map { $0.frame.minX }.min() ?? defaultPanelOrigin.x)
    }

    private static func outerRightX() -> Double {
        Double(NSScreen.screens.map { $0.frame.maxX }.max() ?? defaultPanelOrigin.x)
    }

    /// Checks the panel's position against the outer edges of the full
    /// multi-screen arrangement (not each screen's own edges — only the
    /// leftmost edge of the leftmost monitor and the rightmost edge of the
    /// rightmost one dock; an inner edge between two side-by-side monitors
    /// is just contiguous desktop space) and docks/undocks accordingly.
    private func checkDockSnap() {
        let leftX = Self.outerLeftX()
        let rightX = Self.outerRightX()
        let frame = panel.frame

        if dockState.edge == nil {
            if frame.minX - leftX <= Self.dockThreshold {
                dock(to: .left)
            } else if rightX - frame.maxX <= Self.dockThreshold {
                dock(to: .right)
            }
        } else if let edge = dockState.edge {
            let distance = edge == .left ? (frame.minX - leftX) : (rightX - frame.maxX)
            if distance > Self.undockThreshold {
                undock()
            }
        }
    }

    private func dock(to edge: DockedEdge) {
        let leftX = Self.outerLeftX()
        let rightX = Self.outerRightX()
        let x = edge == .left ? leftX : rightX - Double(Self.dockedSize.width)

        let screen = panel.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? panel.frame
        let y = min(max(panel.frame.midY - Double(Self.dockedSize.height) / 2, visible.minY),
                    visible.maxY - Double(Self.dockedSize.height))

        dockState.edge = edge
        panel.setFrame(NSRect(x: x, y: y, width: Self.dockedSize.width, height: Self.dockedSize.height),
                        display: true, animate: true)
        refreshContextMenu()
        savePanelPosition()
    }

    private func undock() {
        let screen = panel.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? panel.frame
        let y = min(max(panel.frame.midY - Double(Self.floatingSize.height) / 2, visible.minY),
                    visible.maxY - Double(Self.floatingSize.height))

        dockState.edge = nil
        panel.setFrame(NSRect(x: panel.frame.minX, y: y, width: Self.floatingSize.width, height: Self.floatingSize.height),
                        display: true, animate: true)
        refreshContextMenu()
        savePanelPosition()
    }

    private func refreshContextMenu() {
        panel.contentView?.menu = makeContextMenu()
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettingsMenuAction), keyEquivalent: ""))
        menu.addItem(.separator())
        if dockState.edge == nil {
            menu.addItem(NSMenuItem(title: "Dock Left", action: #selector(dockLeftMenuAction), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Dock Right", action: #selector(dockRightMenuAction), keyEquivalent: ""))
        } else {
            menu.addItem(NSMenuItem(title: "Undock", action: #selector(undockMenuAction), keyEquivalent: ""))
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitMenuAction), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc private func openSettingsMenuAction() {
        openSettings()
    }

    @objc private func dockLeftMenuAction() {
        dock(to: .left)
    }

    @objc private func dockRightMenuAction() {
        dock(to: .right)
    }

    @objc private func undockMenuAction() {
        undock()
    }

    @objc private func quitMenuAction() {
        NSApp.terminate(nil)
    }

    /// Keeps the panel's origin within the visible frame of some connected screen,
    /// so a drag past an edge (or a disconnected external monitor) can't strand it
    /// somewhere permanently unreachable.
    private static func clamp(origin: NSPoint, size: NSSize) -> NSPoint {
        let frame = NSRect(origin: origin, size: size)
        let onScreen = NSScreen.screens.contains { $0.visibleFrame.intersects(frame) }
        guard !onScreen, let mainFrame = NSScreen.main?.visibleFrame else { return origin }
        return NSPoint(
            x: min(max(origin.x, mainFrame.minX), mainFrame.maxX - size.width),
            y: min(max(origin.y, mainFrame.minY), mainFrame.maxY - size.height)
        )
    }

    private func savePanelPosition() {
        var config = AppConfig.load() ?? AppConfig(
            fallbackLatitude: nil,
            fallbackLongitude: nil,
            refreshIntervalMinutes: nil,
            opacity: nil,
            panelX: nil,
            panelY: nil
        )
        config.panelX = panel.frame.origin.x
        config.panelY = panel.frame.origin.y
        config.dockedEdge = dockState.edge?.rawValue
        config.save()
    }

    func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(
                onResetPosition: { [weak self] in
                    self?.resetPanelPosition()
                },
                onOpacityChange: { [weak self] value in
                    self?.panel.alphaValue = CGFloat(value)
                }
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 360),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Overcast Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func resetPanelPosition() {
        if dockState.edge != nil {
            undock()
        }
        var config = AppConfig.load() ?? AppConfig(
            fallbackLatitude: nil,
            fallbackLongitude: nil,
            refreshIntervalMinutes: nil,
            opacity: nil,
            panelX: nil,
            panelY: nil
        )
        config.panelX = nil
        config.panelY = nil
        config.dockedEdge = nil
        config.save()
    }
}

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    let app = NSApplication.shared
    app.delegate = delegate
    app.run()
}
