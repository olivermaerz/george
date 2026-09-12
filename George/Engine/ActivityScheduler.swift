import Foundation

@MainActor
final class ActivityScheduler {
    private let settings: AppSettings
    private let activity: UserActivityMonitor
    private let sounds: SoundPlayer
    private var task: Task<Void, Never>?

    private var skipIdle = false

    var onStateChange: ((RunState) -> Void)?

    init(settings: AppSettings, activity: UserActivityMonitor, sounds: SoundPlayer) {
        self.settings = settings
        self.activity = activity
        self.sounds = sounds
    }

    func start(skipIdle: Bool = false) {
        stop()
        self.skipIdle = skipIdle
        activity.markArmed()
        onStateChange?(.waiting)
        task = Task { [weak self] in
            await self?.runLoop()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        skipIdle = false
        sounds.stopAll()
        onStateChange?(.off)
    }

    private func runLoop() async {
        while !Task.isCancelled {
            onStateChange?(.waiting)
            if await waitUntilIdle() == false {
                return
            }
            if Task.isCancelled { return }

            onStateChange?(.running)
            activity.beginRunSession()
            sounds.resetSchedule()
            var moves = 0

            while !Task.isCancelled {
                if activity.didUserInterrupt {
                    sounds.stopAll()
                    break
                }

                activity.beginSynthetic()
                await MouseSimulator.moveHuman(to: ScreenCoordinates.randomWanderPoint())
                activity.endSynthetic()

                if settings.soundsEnabled {
                    sounds.tickAmbient()
                }

                moves += 1
                if moves % max(1, settings.actionEveryNMoves) == 0 {
                    await performOptionalAction()
                }

                if await interruptedDuringWait(nextMoveDelay()) {
                    sounds.stopAll()
                    break
                }
            }
        }
    }

    private func performOptionalAction() async {
        if activity.didUserInterrupt { return }

        let canClick = settings.clicksEnabled && !settings.readyClickTargets.isEmpty
        let canText = settings.textEnabled && !settings.readyTextActions.isEmpty
        guard canClick || canText else { return }

        let useText: Bool
        if canClick && canText {
            useText = Bool.random()
        } else {
            useText = canText
        }

        activity.beginSynthetic()
        defer { activity.endSynthetic() }

        if useText, let (action, phrase) = settings.takeNextTextAction() {
            if settings.soundsEnabled {
                sounds.playTypingBurst()
            }
            await TextActionRunner.run(point: action.point, phrase: phrase, pressEnter: action.pressEnter)
        } else if let target = settings.takeNextClickTarget() {
            await MouseSimulator.moveHuman(to: target.point)
            await MouseSimulator.click(count: target.clickCount)
        }
    }

    private func nextMoveDelay() -> TimeInterval {
        switch settings.movementMode {
        case .interval:
            return max(1, settings.moveIntervalSeconds)
        case .random:
            let minV = min(settings.randomMoveMinSeconds, settings.randomMoveMaxSeconds)
            let maxV = max(settings.randomMoveMinSeconds, settings.randomMoveMaxSeconds)
            return Double.random(in: max(1, minV)...max(1, maxV))
        }
    }

    /// Returns false if cancelled / disarmed.
    private func waitUntilIdle() async -> Bool {
        let timeout = max(1, settings.idleTimeoutSeconds)
        while !Task.isCancelled {
            if skipIdle {
                skipIdle = false
                return true
            }
            if Date().timeIntervalSince(activity.lastRealActivity) >= timeout {
                return true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        return false
    }

    /// Returns true if the user became active (or the task was cancelled).
    private func interruptedDuringWait(_ seconds: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if Task.isCancelled { return true }
            if activity.didUserInterrupt {
                return true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        return Task.isCancelled
    }
}
