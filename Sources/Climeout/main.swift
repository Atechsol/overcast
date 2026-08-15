import SwiftUI
import AppKit

// Entry point for a menubar-less, dock-less floating companion app.
// We use NSApplicationDelegate directly (not the SwiftUI App lifecycle)
// so we have full control over the NSPanel window and can keep this
// out of the Dock / Cmd-Tab switcher.

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel!
    var weatherService = WeatherService()
    var moodManager = MoodManager()
    var eventListener: EventListener?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock + Cmd-Tab: this is a background utility, not a regular app.
        NSApp.setActivationPolicy(.accessory)

        let contentView = ClimeoutView()
            .environmentObject(weatherService)
            .environmentObject(moodManager)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.sizingOptions = [.preferredContentSize]

        panel = FloatingPanel(contentRect: NSRect(x: 100, y: 100, width: 220, height: 120))
        panel.contentView = hostingView
        panel.makeKeyAndOrderFront(nil)

        weatherService.start()
        moodManager.startAutoRotate()

        eventListener = EventListener { [weak self] event in
            self?.moodManager.trigger(event)
        }
    }
}

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    let app = NSApplication.shared
    app.delegate = delegate
    app.run()
}
