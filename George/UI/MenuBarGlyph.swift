import AppKit

enum MenuBarGlyph {
    static func image(running: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let body = NSBezierPath(ovalIn: NSRect(x: 3.2, y: 1.6, width: 11.6, height: 14.2))
            if running {
                NSColor.black.setFill()
                body.fill()
            } else {
                NSColor.black.setStroke()
                body.lineWidth = 1.4
                body.stroke()
            }

            let leftLens = NSBezierPath(ovalIn: NSRect(x: 4.6, y: 8.6, width: 3.4, height: 3.4))
            let rightLens = NSBezierPath(ovalIn: NSRect(x: 10.0, y: 8.6, width: 3.4, height: 3.4))
            let bridge = NSBezierPath()
            bridge.move(to: NSPoint(x: 8.0, y: 10.3))
            bridge.line(to: NSPoint(x: 10.0, y: 10.3))

            if running {
                NSColor.white.setStroke()
            } else {
                NSColor.black.setStroke()
            }
            leftLens.lineWidth = 1.1
            rightLens.lineWidth = 1.1
            bridge.lineWidth = 1.1
            leftLens.stroke()
            rightLens.stroke()
            bridge.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}
