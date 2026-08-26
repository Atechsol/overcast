import SwiftUI
import AppKit

struct OvercastView: View {
    @EnvironmentObject var weatherService: WeatherService
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var dockState: PanelDockState
    @State private var now: Date = Date()
    @State private var frameIndex: Int = 0

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let faceTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let edge = dockState.edge {
                dockedContent
                    .padding(10)
                    .frame(width: 60, height: 170)
                    .background {
                        DockedShape(edge: edge)
                            .fill(Color.black.opacity(0.72))
                            .overlay(DockedShape(edge: edge).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    .clipShape(DockedShape(edge: edge))
                    .compositingGroup()
                    // Smaller radius/offset than the floating card's: at 20/y:8 the
                    // blur needed more clearance than the 30pt shadow padding below
                    // reserved, especially combined with the downward y-offset —
                    // getting clipped by the hosting view's bounds read as a hard,
                    // squared-off edge instead of a soft shadow.
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
                    // Shadow clearance on every side EXCEPT the one flush against the
                    // screen edge — padding that side would push the visible card away
                    // from the edge instead of sitting flush against it.
                    .padding(.top, 30)
                    .padding(.bottom, 30)
                    .padding(.leading, edge == .left ? 0 : 30)
                    .padding(.trailing, edge == .right ? 0 : 30)
            } else {
                floatingContent
                    .padding(12)
                    .frame(width: 150, height: 150)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: 34, style: .continuous)
                        // A plain fill, not .ultraThinMaterial: that's backed by a
                        // separate NSVisualEffectView whose blur ignores clipShape on a
                        // transparent, non-opaque NSPanel — it bled out to a rectangle
                        // instead of following the rounded card.
                        shape
                            .fill(Color.black.opacity(0.72))
                            .overlay(shape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 8)
                    .padding(30) // reserves room so the blurred shadow isn't clipped by the hosting view's bounds
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(clockTimer) { now = $0 }
        .onReceive(faceTimer) { _ in frameIndex += 1 }
    }

    private var floatingContent: some View {
        VStack(spacing: 6) {
            Text(currentFrame)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .contentTransition(.identity)
                .animation(nil, value: frameIndex)

            (
                Text(numericTimeString)
                    .font(.custom("Antonio", size: 20))
                    .fontWeight(.bold)
                + Text(" " + amPmString)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            )
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
                .frame(width: 125)

            if weatherService.needsLocationPermission {
                Button(action: weatherService.openLocationSettings) {
                    Text("Enable Location for accurate weather →")
                        .font(.caption2.weight(.medium))
                        .multilineTextAlignment(.center)
                        .frame(width: 115)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.orange)
            }
        }
    }

    /// Narrow strip shown while docked to a screen edge: weather symbol,
    /// hour and minute each inline (not split into individual stacked
    /// digits) separated by a "__" line, and the AM/PM suffix at the bottom.
    private var dockedContent: some View {
        VStack(spacing: 6) {
            Text(weatherService.currentDescriptor.symbol)
                .font(.title3)

            VStack(spacing: 4) {
                Text(hourString)
                    .font(.custom("Antonio", size: 15))
                    .fontWeight(.bold)
                    .monospacedDigit()

                // A real bar shape, not a Text("__") — the underscore glyph
                // sits low in its own line-height box (near its baseline),
                // so the empty space above it made the gap to the hour line
                // look bigger than the gap to the minute line below, even
                // with equal VStack spacing. A shape has no such asymmetry.
                Capsule()
                    .fill(Color.primary)
                    .frame(width: 14, height: 2)

                Text(minuteString)
                    .font(.custom("Antonio", size: 15))
                    .fontWeight(.bold)
                    .monospacedDigit()
            }

            Text(amPmString)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var currentFrame: String {
        let frames = moodManager.currentMood.frames
        guard !frames.isEmpty else { return "" }
        return frames[frameIndex % frames.count]
    }

    private var numericTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: now)
    }

    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h"
        return formatter.string(from: now)
    }

    private var minuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        return formatter.string(from: now)
    }

    private var amPmString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: now)
    }
}
