import AppKit
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var runState: RunState = .off
    @Published var isTrusted = AccessibilityPermission.isTrusted

    let settings = AppSettings()
    let activity = UserActivityMonitor()
    let sounds = SoundPlayer()

    private var scheduler: ActivityScheduler!
    private var bag = Set<AnyCancellable>()

    var isArmed: Bool { runState != .off }

    var secondsUntilStart: Int {
        let remaining = max(1, settings.idleTimeoutSeconds) - Date().timeIntervalSince(activity.lastRealActivity)
        return max(0, Int(ceil(remaining)))
    }

    init() {
        scheduler = ActivityScheduler(settings: settings, activity: activity, sounds: sounds)
        scheduler.onStateChange = { [weak self] state in
            self?.runState = state
        }

        activity.onPanic = { [weak self] in
            self?.disarm()
        }

        settings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        refreshTrust()

        NotificationCenter.default.publisher(for: .georgeBecameActive)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshTrust()
            }
            .store(in: &bag)
    }

    func toggleArmed() {
        if isArmed {
            disarm()
        } else {
            arm()
        }
    }

    func arm() {
        refreshTrust()
        guard isTrusted else { return }
        activity.start()
        scheduler.start()
    }

    func startNow() {
        refreshTrust()
        guard isTrusted else { return }
        activity.start()
        scheduler.start(skipIdle: true)
    }

    func disarm() {
        scheduler.stop()
        activity.stop()
        runState = .off
    }

    func refreshTrust() {
        isTrusted = AccessibilityPermission.isTrusted
    }

    func openSettings() {
        SettingsPanel.shared.show(appState: self)
    }

    func showAbout() {
        AppActivation.revealForWindow()
        NSApp.applicationIconImage = GeorgeBrand.appIcon()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: GeorgeBrand.name,
            .applicationIcon: GeorgeBrand.appIcon(),
            .credits: GeorgeBrand.aboutCredits()
        ])
    }
}
