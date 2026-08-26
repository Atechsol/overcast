import Foundation

struct Mood {
    /// Cycled on a timer by the view to animate the ASCII face (blink, bounce, etc).
    let frames: [String]
    let message: String

    // Each mood is a single-line kaomoji with 2-3 blink/variant frames —
    // one glyph on screen at a time, not a stacked multi-line figure.
    static let neutral = Mood(frames: [
        "(^_^)",
        "(-_-)"
    ], message: "Ready when you are.")

    static let cheerful = Mood(frames: [
        "(^▽^)",
        "(^o^)"
    ], message: "You've got this today!")

    static let bugFound = Mood(frames: [
        "(o_o)",
        "(O_O)"
    ], message: "Found a bug. Let's squash it.")

    static let focused = Mood(frames: [
        "(-_-)",
        "(-.-)"
    ], message: "Deep focus mode. I'll be quiet.")

    static let celebrating = Mood(frames: [
        "\\(^o^)/",
        "\\(^▽^)/"
    ], message: "Nice, that shipped!")
}

/// Drives the companion's "personality" — a simple, config-driven state machine.
/// Mood changes can be triggered by external events (see EventListener) such as
/// a CI webhook, a file watcher on a log, or a manual command.
@MainActor
final class MoodManager: ObservableObject {
    @Published var currentMood: Mood = .neutral

    private var revertTimer: Timer?
    private var rotateTimer: Timer?

    // Idle personality loop — cycles through moods on its own when nothing else
    // is going on, so the companion feels alive rather than static.
    private let rotation: [Mood] = [.neutral, .cheerful, .bugFound, .celebrating]
    private var rotationIndex = 0

    func startAutoRotate(interval: TimeInterval = 8) {
        rotateTimer?.invalidate()
        rotateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            // Unwrap outside the Task — the CI toolchain's strict-concurrency
            // checker rejects unwrapping a weak `self` inside an already
            // concurrently-executing Task closure, even via `guard let self`.
            guard let self else { return }
            Task { @MainActor [self] in
                self.advanceRotation()
            }
        }
    }

    private func advanceRotation() {
        rotationIndex = (rotationIndex + 1) % rotation.count
        currentMood = rotation[rotationIndex]
    }

    func trigger(_ event: MoodEvent) {
        let mood: Mood
        switch event {
        case .bugFound: mood = .bugFound
        case .cheerUp: mood = .cheerful
        case .buildPassed: mood = .celebrating
        case .focusMode: mood = .focused
        case .reset: mood = .neutral
        }

        // A real event takes priority — pause the idle rotation while it's shown.
        rotateTimer?.invalidate()
        currentMood = mood

        // Auto-revert to neutral (and resume idle rotation) after a while,
        // unless it's focus mode (which the user should exit explicitly).
        revertTimer?.invalidate()
        if event != .focusMode && event != .reset {
            revertTimer = Timer.scheduledTimer(withTimeInterval: 60 * 5, repeats: false) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor [self] in
                    self.currentMood = .neutral
                    self.startAutoRotate()
                }
            }
        } else if event == .reset {
            startAutoRotate()
        }
    }
}

enum MoodEvent: String, Codable {
    case bugFound
    case cheerUp
    case buildPassed
    case focusMode
    case reset
}
