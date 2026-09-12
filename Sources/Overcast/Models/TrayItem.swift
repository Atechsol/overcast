import Foundation

struct TrayItem: Identifiable {
    let id = UUID()
    let url: URL
    let displayName: String
    let byteSize: Int64?
    let isDirectory: Bool

    static func make(from url: URL) -> TrayItem? {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]) else {
            return nil
        }
        return TrayItem(
            url: url,
            displayName: url.lastPathComponent,
            byteSize: values.fileSize.map { Int64($0) },
            isDirectory: values.isDirectory ?? false
        )
    }
}
