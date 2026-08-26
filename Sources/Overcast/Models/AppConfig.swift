import Foundation

/// User-editable configuration, loaded from ~/.config/overcast/config.json
/// Falls back to sensible defaults (San Francisco coords) if missing.
struct AppConfig: Codable {
    var fallbackLatitude: Double?
    var fallbackLongitude: Double?
    var refreshIntervalMinutes: Int?
    var opacity: Double?
    var panelX: Double?
    var panelY: Double?
    var dockedEdge: String?

    static func configURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/overcast/config.json")
    }

    static func load() -> AppConfig? {
        let url = configURL()
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppConfig.self, from: data)
    }

    func save() {
        let url = Self.configURL()
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: url)
    }
}
