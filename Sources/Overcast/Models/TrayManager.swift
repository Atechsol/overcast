import Foundation

/// Dropped files held while the app runs — a temporary shelf, not persisted.
/// Storing file URLs across launches would mean re-validating existence and
/// potential security-scope handling with no other precedent in this codebase;
/// it also contradicts the "temporary shelf" nature of the feature.
@MainActor
final class TrayManager: ObservableObject {
    @Published var items: [TrayItem] = []
    // Single source of truth for expand/collapse, shared between the
    // SwiftUI view (toggle button) and AppDelegate (drag-triggered
    // dock/undock, which needs to force-collapse to keep the actual
    // window size in sync — a local @State on the view alone can't be
    // reached from there).
    @Published var isExpanded = false

    func add(_ urls: [URL]) {
        let new = urls.compactMap(TrayItem.make(from:))
        items.append(contentsOf: new)
    }

    func remove(_ item: TrayItem) {
        items.removeAll { $0.id == item.id }
    }

    func clear() {
        items.removeAll()
    }
}
