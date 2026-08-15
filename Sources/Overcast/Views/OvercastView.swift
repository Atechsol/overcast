import SwiftUI

struct OvercastView: View {
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var moodManager: MoodManager
    @State private var now: Date = Date()
    @State private var frameIndex: Int = 0

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let faceTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 6) {
            Text(currentFrame)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .contentTransition(.identity)
                .animation(nil, value: frameIndex)

            Text(timeString)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 4) {
                Text(weatherService.currentDescriptor.symbol)
                Text(weatherService.currentDescriptor.label)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Text(moodManager.currentMood.message)
                .font(.caption2)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 180)

            if weatherService.needsLocationPermission {
                Button(action: weatherService.openLocationSettings) {
                    Text("Enable Location for accurate weather →")
                        .font(.caption2.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.orange)
            }
        }
        .padding(18)
        .background {
            let shape = RoundedRectangle(cornerRadius: 34, style: .continuous)
            shape
                .fill(.ultraThinMaterial)
                .overlay(shape.fill(Color.black.opacity(0.45)))
                .overlay(shape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .compositingGroup()
        .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 8)
        .preferredColorScheme(.dark)
        .fixedSize()
        .onReceive(clockTimer) { now = $0 }
        .onReceive(faceTimer) { _ in frameIndex += 1 }
    }

    private var currentFrame: String {
        let frames = moodManager.currentMood.frames
        guard !frames.isEmpty else { return "" }
        return frames[frameIndex % frames.count]
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: now)
    }
}
