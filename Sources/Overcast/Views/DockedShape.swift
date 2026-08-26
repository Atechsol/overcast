import SwiftUI

/// A rounded rect with only the two inward corners rounded — the edge
/// touching the screen border sits flush/flat instead of curving away
/// from it. macOS 13's SwiftUI has no built-in per-corner rounding
/// (UnevenRoundedRectangle needs macOS 14), so this is hand-rolled.
struct DockedShape: Shape {
    let edge: DockedEdge
    var radius: CGFloat = 24

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch edge {
        case .left:
            // Flat left edge (against the screen border); rounded right corners.
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(
                tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                tangent2End: CGPoint(x: rect.maxX, y: rect.minY + radius),
                radius: radius
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(
                tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                tangent2End: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                radius: radius
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .right:
            // Flat right edge (against the screen border); rounded left corners.
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addArc(
                tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                tangent2End: CGPoint(x: rect.minX, y: rect.minY + radius),
                radius: radius
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
            path.addArc(
                tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                tangent2End: CGPoint(x: rect.minX + radius, y: rect.maxY),
                radius: radius
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}
