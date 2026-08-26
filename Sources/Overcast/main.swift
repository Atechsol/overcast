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
    var eventListener: EventListener?

    static let defaultPanelOrigin = NSPoint(x: 100, y: 100)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock + Cmd-Tab: this is a background utility, not a regular app.
        NSApp.setActivationPolicy(.accessory)

        let contentView = OvercastView()
            .environmentObject(weatherService)
            .environmentObject(moodManager)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.sizingOptions = [.preferredContentSize]
        hostingView.menu = makeContextMenu()

        let panelSize = NSSize(width: 220, height: 120)
        let config = AppConfig.load()
        let savedOrigin = NSPoint(x: config?.panelX ?? Double(Self.defaultPanelOrigin.x),
                                   y: config?.panelY ?? Double(Self.defaultPanelOrigin.y))
        let origin = Self.clamp(origin: savedOrigin, size: panelSize)

        panel = FloatingPanel(contentRect: NSRect(origin: origin, size: panelSize))
        panel.contentView = hostingView
        panel.alphaValue = config?.opacity.map { CGFloat($0) } ?? 1.0
        panel.makeKeyAndOrderFront(nil)

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
            Task { @MainActor in
                guard let self else { return }
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

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettingsMenuAction), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitMenuAction), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc private func openSettingsMenuAction() {
        openSettings()
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
        config.save()
    }

    func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView { [weak self] in
                self?.resetPanelPosition()
            }
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
        config.save()
    }
}

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    let app = NSApplication.shared
    app.delegate = delegate
    app.run()
}
