import SwiftUI

struct SettingsView: View {
    @State private var latitude: String
    @State private var longitude: String
    @State private var refreshIntervalMinutes: Int
    @State private var opacity: Double
    @State private var saved = false

    let onResetPosition: () -> Void
    let onOpacityChange: (Double) -> Void

    init(onResetPosition: @escaping () -> Void, onOpacityChange: @escaping (Double) -> Void) {
        self.onResetPosition = onResetPosition
        self.onOpacityChange = onOpacityChange
        let config = AppConfig.load()
        _latitude = State(initialValue: config?.fallbackLatitude.map { String($0) } ?? "")
        _longitude = State(initialValue: config?.fallbackLongitude.map { String($0) } ?? "")
        _refreshIntervalMinutes = State(initialValue: config?.refreshIntervalMinutes ?? 15)
        _opacity = State(initialValue: config?.opacity ?? 1.0)
    }

    var body: some View {
        Form {
            Section("Fallback Location") {
                TextField("Latitude", text: $latitude)
                TextField("Longitude", text: $longitude)
            }

            Section("Weather") {
                Stepper("Refresh every \(refreshIntervalMinutes) min", value: $refreshIntervalMinutes, in: 5...120, step: 5)
            }

            Section("Appearance") {
                Slider(value: $opacity, in: 0.2...1.0) {
                    Text("Opacity")
                }
                .onChange(of: opacity) { newValue in
                    onOpacityChange(newValue)
                    persistOpacity(newValue)
                }
                Button("Reset Position") {
                    onResetPosition()
                }
            }

            if saved {
                Text("Saved — restart Overcast to apply location/refresh changes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Save") {
                save()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .frame(width: 320)
    }

    private func persistOpacity(_ value: Double) {
        var config = AppConfig.load() ?? AppConfig(
            fallbackLatitude: nil,
            fallbackLongitude: nil,
            refreshIntervalMinutes: nil,
            opacity: nil,
            panelX: nil,
            panelY: nil
        )
        config.opacity = value
        config.save()
    }

    private func save() {
        var config = AppConfig.load() ?? AppConfig(
            fallbackLatitude: nil,
            fallbackLongitude: nil,
            refreshIntervalMinutes: nil,
            opacity: nil,
            panelX: nil,
            panelY: nil
        )
        config.fallbackLatitude = Double(latitude)
        config.fallbackLongitude = Double(longitude)
        config.refreshIntervalMinutes = refreshIntervalMinutes
        config.opacity = opacity
        config.save()
        saved = true
    }
}
