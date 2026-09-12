import AppKit

enum ScreenCoordinates {
    /// Height of the primary display in Cocoa space (origin at its bottom-left).
    static var primaryHeight: CGFloat {
        NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 0
    }

    static func quartz(fromCocoa point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: primaryHeight - point.y)
    }

    static func cocoa(fromQuartz point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: primaryHeight - point.y)
    }

    static func randomWanderPoint() -> CGPoint {
        let screen = NSScreen.screens.randomElement() ?? NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.visibleFrame
        let inset: CGFloat = 48
        let minX = frame.minX + inset
        let maxX = max(minX, frame.maxX - inset)
        let minY = frame.minY + inset
        let maxY = max(minY, frame.maxY - inset)
        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }
}
