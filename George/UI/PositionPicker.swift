import AppKit

@MainActor
enum PositionPicker {
    static func pick() async -> CGPoint? {
        await OverlayController.shared.pick()
    }
}

@MainActor
private final class OverlayController {
    static let shared = OverlayController()

    private var windows: [NSWindow] = []
    private var continuation: CheckedContinuation<CGPoint?, Never>?

    func pick() async -> CGPoint? {
        finish(nil)
        NSApp.activate(ignoringOtherApps: true)
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            show()
        }
    }

    fileprivate func finish(_ point: CGPoint?) {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        if let continuation {
            self.continuation = nil
            continuation.resume(returning: point)
        }
    }

    private func show() {
        for screen in NSScreen.screens {
            let overlay = OverlayView(frame: screen.frame)
            overlay.onPick = { [weak self] point in
                self?.finish(point)
            }
            overlay.onCancel = { [weak self] in
                self?.finish(nil)
            }

            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.contentView = overlay
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
    }
}

private final class OverlayView: NSView {
    var onPick: ((CGPoint) -> Void)?
    var onCancel: (() -> Void)?
    private var cursor = NSEvent.mouseLocation
    private var tracking: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        resetTracking()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        resetTracking()
    }

    override func mouseMoved(with event: NSEvent) {
        cursor = NSEvent.mouseLocation
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        onPick?(NSEvent.mouseLocation)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.18).setFill()
        bounds.fill()

        guard let window else { return }
        let local = window.convertPoint(fromScreen: cursor)

        let path = NSBezierPath()
        path.move(to: NSPoint(x: local.x, y: bounds.minY))
        path.line(to: NSPoint(x: local.x, y: bounds.maxY))
        path.move(to: NSPoint(x: bounds.minX, y: local.y))
        path.line(to: NSPoint(x: bounds.maxX, y: local.y))
        NSColor.white.withAlphaComponent(0.85).setStroke()
        path.lineWidth = 1
        path.stroke()

        let ring = NSBezierPath(ovalIn: NSRect(x: local.x - 8, y: local.y - 8, width: 16, height: 16))
        NSColor.systemBlue.setStroke()
        ring.lineWidth = 2
        ring.stroke()

        let label = "Click to set position  ·  Esc to cancel   \(Int(cursor.x)), \(Int(cursor.y))" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = label.size(withAttributes: attrs)
        let box = NSRect(
            x: bounds.midX - size.width / 2 - 12,
            y: bounds.maxY - size.height - 36,
            width: size.width + 24,
            height: size.height + 12
        )
        NSColor.black.withAlphaComponent(0.55).setFill()
        NSBezierPath(roundedRect: box, xRadius: 8, yRadius: 8).fill()
        label.draw(at: NSPoint(x: box.minX + 12, y: box.minY + 6), withAttributes: attrs)
    }

    private func resetTracking() {
        if let tracking {
            removeTrackingArea(tracking)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }
}
