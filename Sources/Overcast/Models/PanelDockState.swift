import Foundation

enum DockedEdge: String, Codable {
    case left
    case right
}

/// Published to the SwiftUI content view so it can switch between the
/// floating square and the narrow docked-strip layout.
@MainActor
final class PanelDockState: ObservableObject {
    @Published var edge: DockedEdge?
}
