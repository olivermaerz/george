import AppKit
import SwiftUI

@main
struct GeorgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(appState.settings)
        } label: {
            MenuBarLabel(runState: appState.runState)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.applicationIconImage = GeorgeBrand.appIcon()
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                AppActivation.revertToAccessoryIfNeeded()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Trust can change while System Settings is open.
        NotificationCenter.default.post(name: .georgeBecameActive, object: nil)
    }
}

extension Notification.Name {
    static let georgeBecameActive = Notification.Name("georgeBecameActive")
}
