import Foundation

/// User-editable configuration, loaded from ~/.config/climeout/config.json
/// Falls back to sensible defaults (San Francisco coords) if missing.
struct AppConfig: Decodable {
    let fallbackLatitude: Double?
    let fallbackLongitude: Double?
    let refreshIntervalMinutes: Int?

    static func configURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/climeout/config.json")
    }

    static func load() -> AppConfig? {
        let url = configURL()
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppConfig.self, from: data)
    }
}
