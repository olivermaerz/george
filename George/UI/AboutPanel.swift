import AppKit
import SwiftUI

@MainActor
final class AboutPanel {
    static let shared = AboutPanel()

    private var window: NSWindow?

    func show() {
        AppActivation.revealForWindow()

        if let window {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(contentViewController: NSHostingController(rootView: AboutView()))
        window.title = "About \(GeorgeBrand.name)"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.setContentSize(NSSize(width: 440, height: 340))
        window.center()
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("george-about")
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        self.window = window
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
}
