import Foundation
import Combine

struct SettingsSnapshot: Codable, Equatable {
    var idleTimeoutSeconds: Double
    var movementMode: MovementMode
    var moveIntervalSeconds: Double
    var randomMoveMinSeconds: Double
    var randomMoveMaxSeconds: Double
    var actionEveryNMoves: Int
    var clicksEnabled: Bool
    var clickOrder: SelectionOrder
    var clickCursor: Int
    var clickTargets: [ClickTarget]
    var textEnabled: Bool
    var textActionOrder: SelectionOrder
    var textCursor: Int
    var textActions: [TextAction]
    var soundsEnabled: Bool

    static let `default` = SettingsSnapshot(
        idleTimeoutSeconds: 60,
        movementMode: .interval,
        moveIntervalSeconds: 15,
        randomMoveMinSeconds: 8,
        randomMoveMaxSeconds: 45,
        actionEveryNMoves: 5,
        clicksEnabled: false,
        clickOrder: .random,
        clickCursor: 0,
        clickTargets: [],
        textEnabled: false,
        textActionOrder: .sequential,
        textCursor: 0,
        textActions: [],
        soundsEnabled: false
    )
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var idleTimeoutSeconds: Double
    @Published var movementMode: MovementMode
    @Published var moveIntervalSeconds: Double
    @Published var randomMoveMinSeconds: Double
    @Published var randomMoveMaxSeconds: Double
    @Published var actionEveryNMoves: Int
    @Published var clicksEnabled: Bool
    @Published var clickOrder: SelectionOrder
    @Published var clickCursor: Int
    @Published var clickTargets: [ClickTarget]
    @Published var textEnabled: Bool
    @Published var textActionOrder: SelectionOrder
    @Published var textCursor: Int
    @Published var textActions: [TextAction]
    @Published var soundsEnabled: Bool

    private let defaultsKey = "george.settings.v1"
    private var isLoading = false
    private var persistBag = Set<AnyCancellable>()

    init() {
        let loaded = Self.loadFromDefaults()
        idleTimeoutSeconds = loaded.idleTimeoutSeconds
        movementMode = loaded.movementMode
        moveIntervalSeconds = loaded.moveIntervalSeconds
        randomMoveMinSeconds = loaded.randomMoveMinSeconds
        randomMoveMaxSeconds = loaded.randomMoveMaxSeconds
        actionEveryNMoves = loaded.actionEveryNMoves
        clicksEnabled = loaded.clicksEnabled
        clickOrder = loaded.clickOrder
        clickCursor = loaded.clickCursor
        clickTargets = loaded.clickTargets
        textEnabled = loaded.textEnabled
        textActionOrder = loaded.textActionOrder
        textCursor = loaded.textCursor
        textActions = loaded.textActions
        soundsEnabled = loaded.soundsEnabled

        objectWillChange
            .debounce(for: .milliseconds(80), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.persist()
            }
            .store(in: &persistBag)
    }

    var snapshot: SettingsSnapshot {
        SettingsSnapshot(
            idleTimeoutSeconds: idleTimeoutSeconds,
            movementMode: movementMode,
            moveIntervalSeconds: moveIntervalSeconds,
            randomMoveMinSeconds: min(randomMoveMinSeconds, randomMoveMaxSeconds),
            randomMoveMaxSeconds: max(randomMoveMinSeconds, randomMoveMaxSeconds),
            actionEveryNMoves: max(1, actionEveryNMoves),
            clicksEnabled: clicksEnabled,
            clickOrder: clickOrder,
            clickCursor: clickCursor,
            clickTargets: clickTargets,
            textEnabled: textEnabled,
            textActionOrder: textActionOrder,
            textCursor: textCursor,
            textActions: textActions,
            soundsEnabled: soundsEnabled
        )
    }

    var readyClickTargets: [ClickTarget] {
        clickTargets.filter { $0.enabled && $0.hasPosition && $0.clickCount > 0 }
    }

    var readyTextActions: [TextAction] {
        textActions.filter(\.isReady)
    }

    func addClickTarget() {
        clickTargets.append(.make(index: clickTargets.count + 1))
    }

    func addTextAction() {
        textActions.append(.make(index: textActions.count + 1))
    }

    func takeNextClickTarget() -> ClickTarget? {
        let ready = readyClickTargets
        guard !ready.isEmpty else { return nil }
        switch clickOrder {
        case .random:
            return ready.randomElement()
        case .sequential:
            let target = ready[clickCursor % ready.count]
            clickCursor += 1
            return target
        }
    }

    func takeNextTextAction() -> (TextAction, String)? {
        let ready = readyTextActions
        guard !ready.isEmpty else { return nil }

        let chosen: TextAction
        switch textActionOrder {
        case .random:
            chosen = ready.randomElement() ?? ready[0]
        case .sequential:
            chosen = ready[textCursor % ready.count]
            textCursor += 1
        }

        guard let index = textActions.firstIndex(where: { $0.id == chosen.id }) else { return nil }
        var updated = textActions[index]
        guard let phrase = updated.takePhrase() else { return nil }
        textActions[index] = updated
        return (updated, phrase)
    }

    private func persist() {
        guard !isLoading else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private static func loadFromDefaults() -> SettingsSnapshot {
        guard
            let data = UserDefaults.standard.data(forKey: "george.settings.v1"),
            let decoded = try? JSONDecoder().decode(SettingsSnapshot.self, from: data)
        else {
            return .default
        }
        return decoded
    }
}
