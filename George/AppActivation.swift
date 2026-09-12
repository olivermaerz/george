import AppKit

enum AppActivation {
    static func revealForWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    static func revertToAccessoryIfNeeded() {
        let keepVisible = NSApp.windows.contains { window in
            window.isVisible
                && window.canBecomeKey
                && window.level == .normal
        }
        if !keepVisible {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
