import AppKit
import ApplicationServices

enum AccessibilityPermission {
    /// Never use `AXIsProcessTrustedWithOptions` with the prompt flag.
    /// That call makes macOS uncheck an already-granted Accessibility entry.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]
        for value in candidates {
            if let url = URL(string: value) {
                NSWorkspace.shared.open(url)
                return
            }
        }
    }

    static func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    /// Quit fully, then start a new process so TCC can attach to a fresh launch.
    static func relaunch() {
        let path = Bundle.main.bundlePath
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 0.8; /usr/bin/open '\(escaped)'"]
        try? process.run()
        NSApp.terminate(nil)
    }
}
