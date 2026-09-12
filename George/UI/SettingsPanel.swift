import AppKit
import SwiftUI

@MainActor
final class SettingsPanel {
    static let shared = SettingsPanel()

    private var window: NSWindow?

    func show(appState: AppState) {
        AppActivation.revealForWindow()

        if let window {
            window.contentViewController = hostingController(appState: appState)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(contentViewController: hostingController(appState: appState))
        window.title = "George Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.backgroundColor = .clear
        window.setContentSize(NSSize(width: 660, height: 620))
        window.minSize = NSSize(width: 600, height: 520)
        window.center()
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("george-settings")
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        self.window = window
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hostingController(appState: AppState) -> NSHostingController<some View> {
        NSHostingController(
            rootView: SettingsView()
                .environmentObject(appState)
                .environmentObject(appState.settings)
        )
    }
}
