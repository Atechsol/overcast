import Foundation
import CoreLocation
import Combine
import AppKit

@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentDescriptor: WeatherDescriptor = .unknown
    @Published var needsLocationPermission: Bool = false

    private let locationManager = CLLocationManager()
    private var refreshTimer: Timer?

    // Fallback coordinates if location permission is denied / unavailable.
    // Configurable via AppConfig (see Config/config.json).
    private var fallbackLatitude: Double = 37.7749
    private var fallbackLongitude: Double = -122.4194
    private var refreshIntervalMinutes: Double = 15

    override init() {
        super.init()
        locationManager.delegate = self
        loadFallbackFromConfig()
    }

    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()

        // Configurable via AppConfig (see ~/.config/overcast/config.json), defaults to 15 min.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshIntervalMinutes * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                await self.fetchWeather()
            }
        }
    }

    private func loadFallbackFromConfig() {
        guard let config = AppConfig.load() else { return }
        if let lat = config.fallbackLatitude, let lon = config.fallbackLongitude {
            fallbackLatitude = lat
            fallbackLongitude = lon
        }
        if let minutes = config.refreshIntervalMinutes {
            refreshIntervalMinutes = Double(minutes)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.needsLocationPermission = false
            await fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            await fetchWeather()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .denied, .restricted:
                self.needsLocationPermission = true
                await fetchWeather()
            case .authorizedAlways, .authorized:
                self.needsLocationPermission = false
                manager.requestLocation()
            default:
                break
            }
        }
    }

    /// Deep-links straight to the Location Services pane in System Settings.
    func openLocationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }

    func fetchWeather() async {
        await fetchWeather(lat: fallbackLatitude, lon: fallbackLongitude)
    }

    func fetchWeather(lat: Double, lon: Double) async {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "current", value: "weather_code,is_day")
        ]

        guard let url = components.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let descriptor = WeatherDescriptor.from(
                code: decoded.current.weather_code,
                isDay: decoded.current.is_day == 1
            )
            self.currentDescriptor = descriptor
        } catch {
            print("Weather fetch failed: \(error)")
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let weather_code: Int
        let is_day: Int
    }
    let current: Current
}
