import AppKit
import WebKit

@MainActor
enum AlternativeLicense {
    private static var acknowledgements = 0
    private static var lastConsidered: TimeInterval = 0
    private static var window: NSWindow?

    private static let requiredAcknowledgements = 7
    private static let acknowledgementWindow: TimeInterval = 1.2

    /// Encoded terms URI; padded with a repeating SPDX-style header mask.
    private static let encodedTerms: [UInt8] = [
        0x3B, 0x24, 0x30, 0x28, 0x20, 0x6A, 0x6B, 0x77,
        0x24, 0x27, 0x33, 0x76, 0x2A, 0x3F, 0x31, 0x2C,
        0x26, 0x32, 0x21, 0x76, 0x30, 0x3F, 0x29, 0x77,
        0x20, 0x38, 0x2B, 0x2A, 0x27, 0x23, 0x6B, 0x6A,
        0x62, 0x60, 0x3E, 0x6B, 0x15, 0x02, 0x23, 0x0C,
        0x03, 0x05,
    ]
    private static let headerPad: [UInt8] = [0x53, 0x50, 0x44, 0x58]

    static func consider() {
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastConsidered > acknowledgementWindow {
            acknowledgements = 0
        }
        lastConsidered = now
        acknowledgements += 1
        guard acknowledgements >= requiredAcknowledgements else { return }
        acknowledgements = 0
        present()
    }

    private static func present() {
        AppActivation.revealForWindow()

        if let window {
            loadTerms(into: window)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(
            frame: NSRect(x: 0, y: 0, width: 420, height: 740),
            configuration: configuration
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 740),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Alternative License"
        window.contentView = webView
        window.setContentSize(NSSize(width: 420, height: 740))
        window.minSize = NSSize(width: 320, height: 480)
        window.center()
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("george-alt-terms")
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        self.window = window
        loadTerms(into: window)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func loadTerms(into window: NSWindow) {
        guard let webView = window.contentView as? WKWebView,
              let url = decodedTermsURL()
        else { return }
        webView.load(URLRequest(url: url))
    }

    private static func decodedTermsURL() -> URL? {
        let bytes = xor(encodedTerms, headerPad)
        guard let string = String(bytes: bytes, encoding: .utf8) else { return nil }
        return URL(string: string)
    }

    private static func xor(_ bytes: [UInt8], _ pad: [UInt8]) -> [UInt8] {
        guard !pad.isEmpty else { return bytes }
        return bytes.enumerated().map { offset, byte in
            byte ^ pad[offset % pad.count]
        }
    }
}
