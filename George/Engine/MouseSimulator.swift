import AppKit
import CoreGraphics

enum Keyboard {
    static let vKey: CGKeyCode = 9
    static let returnKey: CGKeyCode = 36

    static func paste() {
        postKey(vKey, flags: .maskCommand)
    }

    static func enter() {
        postKey(returnKey)
    }

    static func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let source = CGEventSource(stateID: .hidSystemState)
        if let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            down.flags = flags
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            up.flags = flags
            up.post(tap: .cghidEventTap)
        }
    }
}

enum MouseSimulator {
    static func currentCocoaPoint() -> CGPoint {
        NSEvent.mouseLocation
    }

    static func moveHuman(to destination: CGPoint) async {
        let start = currentCocoaPoint()
        let distance = hypot(destination.x - start.x, destination.y - start.y)
        if distance < 2 {
            postMove(destination)
            return
        }

        let duration = min(1.35, max(0.32, distance / 920))
        let steps = max(14, Int(duration * 95))
        let path = curvedPath(from: start, to: destination)

        for step in 0...steps {
            if Task.isCancelled { return }
            let t = easeInOut(CGFloat(step) / CGFloat(steps))
            postMove(pointOnPath(path, t: t))
            let slice = duration / Double(steps)
            try? await Task.sleep(nanoseconds: UInt64(slice * 1_000_000_000))
        }
        postMove(destination)
    }

    static func click(count: Int) async {
        let source = CGEventSource(stateID: .hidSystemState)
        let quartz = ScreenCoordinates.quartz(fromCocoa: currentCocoaPoint())
        let times = max(1, count)

        for index in 0..<times {
            if Task.isCancelled { return }
            if let down = CGEvent(
                mouseEventSource: source,
                mouseType: .leftMouseDown,
                mouseCursorPosition: quartz,
                mouseButton: .left
            ) {
                down.post(tap: .cghidEventTap)
            }
            try? await Task.sleep(nanoseconds: UInt64.random(in: 40_000_000...120_000_000))
            if let up = CGEvent(
                mouseEventSource: source,
                mouseType: .leftMouseUp,
                mouseCursorPosition: quartz,
                mouseButton: .left
            ) {
                up.post(tap: .cghidEventTap)
            }
            if index + 1 < times {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 120_000_000...280_000_000))
            }
        }
    }

    private static func postMove(_ cocoa: CGPoint) {
        let quartz = ScreenCoordinates.quartz(fromCocoa: cocoa)
        let current = ScreenCoordinates.quartz(fromCocoa: currentCocoaPoint())
        let deltaX = quartz.x - current.x
        let deltaY = quartz.y - current.y

        // Posting a mouse-moved event alone often does not move the on-screen
        // cursor on recent macOS. Warp it, then inject the HID event so apps
        // still see activity.
        CGWarpMouseCursorPosition(quartz)
        CGAssociateMouseAndMouseCursorPosition(1)

        let source = CGEventSource(stateID: .hidSystemState)
        source?.localEventsSuppressionInterval = 0
        if let event = CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: quartz,
            mouseButton: .left
        ) {
            event.setIntegerValueField(.mouseEventDeltaX, value: Int64(deltaX))
            event.setIntegerValueField(.mouseEventDeltaY, value: Int64(deltaY))
            event.post(tap: .cghidEventTap)
        }
    }

    private static func curvedPath(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        let extras = Int.random(in: 1...3)
        var points = [start]
        for index in 1...extras {
            let t = CGFloat(index) / CGFloat(extras + 1)
            let along = lerp(start, end, t)
            let dx = end.x - start.x
            let dy = end.y - start.y
            let length = max(1, hypot(dx, dy))
            let offset = CGFloat.random(in: -90...90)
            points.append(
                CGPoint(
                    x: along.x + (-dy / length) * offset,
                    y: along.y + (dx / length) * offset
                )
            )
        }
        points.append(end)
        return points
    }

    private static func pointOnPath(_ points: [CGPoint], t: CGFloat) -> CGPoint {
        guard points.count >= 2 else { return points.first ?? .zero }
        if points.count == 2 {
            return lerp(points[0], points[1], t)
        }
        // De Casteljau for 3–5 points.
        var layer = points
        let u = min(1, max(0, t))
        while layer.count > 1 {
            var next: [CGPoint] = []
            next.reserveCapacity(layer.count - 1)
            for index in 0..<(layer.count - 1) {
                next.append(lerp(layer[index], layer[index + 1], u))
            }
            layer = next
        }
        return layer[0]
    }

    private static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    private static func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }
}
