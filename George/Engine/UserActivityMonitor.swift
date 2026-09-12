import AppKit
import Combine
import CoreGraphics
enum IdleClock {
    /// Same as `kCGAnyInputEventType` — last keyboard, mouse, or tablet input.
    private static let anyInput = CGEventType(rawValue: UInt32.max)!

    static var secondsIdle: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: anyInput)
    }
}

@MainActor
final class UserActivityMonitor: ObservableObject {
    private(set) var lastRealActivity = Date()
    var onPanic: (() -> Void)?

    private var syntheticDepth = 0
    private var ignoreUntil = Date.distantPast
    private var runSessionStart = Date.distantPast
    private var lastMouseLocation: CGPoint?
    private var monitors: [Any] = []
    private let processID = Int64(ProcessInfo.processInfo.processIdentifier)

    var isSynthetic: Bool { syntheticDepth > 0 }

    var didUserInterrupt: Bool {
        lastRealActivity > runSessionStart
    }

    func start() {
        guard monitors.isEmpty else { return }

        let globalMask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .leftMouseDragged,
            .rightMouseDragged,
            .keyDown,
            .scrollWheel
        ]

        let handler: (NSEvent) -> Void = { [weak self] event in
            Task { @MainActor in
                self?.handle(event)
            }
        }

        // Global monitors see other apps only. Do not install them until trusted —
        // an untrusted tap makes macOS uncheck Accessibility.
        if let global = NSEvent.addGlobalMonitorForEvents(matching: globalMask, handler: handler) {
            monitors.append(global)
        }

        // Local events are George's own UI. Only keep the panic hotkey here so
        // hovering Settings does not reset the idle timer.
        let localMask: NSEvent.EventTypeMask = [.keyDown]
        if let local = NSEvent.addLocalMonitorForEvents(matching: localMask, handler: { event in
            handler(event)
            return event
        }) {
            monitors.append(local)
        }
    }

    func stop() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors.removeAll()
        lastMouseLocation = nil
    }

    func beginSynthetic() {
        syntheticDepth += 1
    }

    func endSynthetic() {
        syntheticDepth = max(0, syntheticDepth - 1)
        if syntheticDepth == 0 {
            ignoreUntil = Date().addingTimeInterval(1.0)
        }
    }

    func markArmed() {
        lastRealActivity = Date()
        runSessionStart = Date.distantPast
    }

    func beginRunSession() {
        runSessionStart = Date()
        ignoreUntil = Date().addingTimeInterval(1.0)
    }

    private func handle(_ event: NSEvent) {
        if event.type == .keyDown {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 53, flags.contains(.option), flags.contains(.shift) {
                onPanic?()
                return
            }
        }

        if Date() < ignoreUntil {
            return
        }

        if isSynthetic,
           event.cgEvent?.getIntegerValueField(.eventSourceUnixProcessID) == processID {
            return
        }

        if event.type == .mouseMoved || event.type == .leftMouseDragged || event.type == .rightMouseDragged {
            let location = NSEvent.mouseLocation
            if let previous = lastMouseLocation, hypot(location.x - previous.x, location.y - previous.y) < 4 {
                lastMouseLocation = location
                return
            }
            lastMouseLocation = location
        }

        lastRealActivity = Date()
    }
}
