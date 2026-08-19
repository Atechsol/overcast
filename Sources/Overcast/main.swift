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

        let config = AppConfig.load()
        let origin = NSPoint(x: config?.panelX ?? Double(Self.defaultPanelOrigin.x),
                              y: config?.panelY ?? Double(Self.defaultPanelOrigin.y))

        panel = FloatingPanel(contentRect: NSRect(origin: origin, size: NSSize(width: 220, height: 120)))
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
            Task { @MainActor in self?.savePanelPosition() }
        }
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
