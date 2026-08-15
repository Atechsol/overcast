import Foundation

struct WeatherDescriptor {
    let label: String
    let symbol: String

    static let unknown = WeatherDescriptor(label: "Unknown", symbol: "❓")

    /// Maps Open-Meteo's WMO weather codes to human-readable, developer-friendly labels.
    /// Reference: https://open-meteo.com/en/docs (WMO Weather interpretation codes)
    static func from(code: Int, isDay: Bool) -> WeatherDescriptor {
        switch code {
        case 0:
            return isDay ? WeatherDescriptor(label: "Sunny", symbol: "☀️")
                          : WeatherDescriptor(label: "Clear Night", symbol: "🌙")
        case 1:
            return WeatherDescriptor(label: "Mild Sun", symbol: "🌤️")
        case 2:
            return WeatherDescriptor(label: "Partly Cloudy", symbol: "⛅")
        case 3:
            return WeatherDescriptor(label: "Overcast", symbol: "☁️")
        case 45, 48:
            return WeatherDescriptor(label: "Foggy", symbol: "🌫️")
        case 51, 53, 55:
            return WeatherDescriptor(label: "Drizzle", symbol: "🌦️")
        case 56, 57:
            return WeatherDescriptor(label: "Freezing Drizzle", symbol: "🌧️")
        case 61, 63, 65:
            return WeatherDescriptor(label: "Rainy", symbol: "🌧️")
        case 66, 67:
            return WeatherDescriptor(label: "Freezing Rain", symbol: "🌨️")
        case 71, 73, 75, 77:
            return WeatherDescriptor(label: "Snowy", symbol: "❄️")
        case 80, 81, 82:
            return WeatherDescriptor(label: "Showers", symbol: "🌦️")
        case 85, 86:
            return WeatherDescriptor(label: "Snow Showers", symbol: "🌨️")
        case 95:
            return WeatherDescriptor(label: "Thunderstorm", symbol: "⛈️")
        case 96, 99:
            return WeatherDescriptor(label: "Severe Storm", symbol: "⛈️")
        default:
            return .unknown
        }
    }
}
