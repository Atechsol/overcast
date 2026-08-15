import Foundation

/// Watches a simple trigger file (~/.config/climeout/event.json) for changes.
/// Any script — a git hook, CI job, or manual `echo` — can write an event here
/// to make the companion react, e.g.:
///
///   echo '{"event":"bugFound"}' > ~/.config/climeout/event.json
///
/// This keeps the integration surface dead simple and language-agnostic —
/// no daemon, no socket, no auth to worry about.
final class EventListener {
    private var source: DispatchSourceFileSystemObject?
    private let fileURL: URL
    private let onEvent: (MoodEvent) -> Void

    init(onEvent: @escaping (MoodEvent) -> Void) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.fileURL = home.appendingPathComponent(".config/climeout/event.json")
        self.onEvent = onEvent
        ensureFileExists()
        watch()
    }

    private func ensureFileExists() {
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: Data("{}".utf8))
        }
    }

    private func watch() {
        let fd = open(fileURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )
        source?.setEventHandler { [weak self] in
            self?.readEvent()
        }
        source?.setCancelHandler { close(fd) }
        source?.resume()
    }

    private func readEvent() {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(EventPayload.self, from: data) else { return }
        onEvent(payload.event)
    }
}

private struct EventPayload: Decodable {
    let event: MoodEvent
}
