import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "slider.horizontal.3") }
            ClicksSettingsView()
                .tabItem { Label("Clicks", systemImage: "hand.tap") }
            TextSettingsView()
                .tabItem { Label("Text", systemImage: "text.cursor") }
        }
        .environmentObject(appState)
        .environmentObject(settings)
        .frame(minWidth: 640, minHeight: 560)
        .background(VisualEffectBackdrop().ignoresSafeArea())
    }
}

private struct SettingsStack<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content()
            }
            .padding(22)
        }
    }
}

private struct GeneralSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        SettingsStack {
            GlassCard {
                HStack(spacing: 14) {
                    Image(nsImage: GeorgeBrand.appIcon())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(GeorgeBrand.name)
                            .font(.title2.weight(.bold))
                        Text(GeorgeBrand.tagline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }

            GlassSectionLabel(title: "Idle")
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Start after inactivity")
                        .font(.headline)
                    HStack(alignment: .bottom, spacing: 12) {
                        ProminentNumberField(value: $settings.idleTimeoutSeconds, width: 96)
                        Text("seconds")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 6)
                        Spacer(minLength: 0)
                    }
                    Text("George waits this long after your last real mouse or keyboard activity, then starts moving.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GlassSectionLabel(title: "Mouse movement")
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scenario")
                            .font(.headline)
                        Picker("Scenario", selection: $settings.movementMode) {
                            ForEach(MovementMode.allCases) { mode in
                                Text(mode.shortTitle).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Text(settings.movementMode.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if settings.movementMode == .interval {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Move every")
                                .font(.headline)
                            HStack(alignment: .bottom, spacing: 12) {
                                ProminentNumberField(value: $settings.moveIntervalSeconds, width: 84)
                                Text("seconds")
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 6)
                                Spacer(minLength: 0)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Random wait")
                                .font(.headline)
                            HStack(alignment: .bottom, spacing: 14) {
                                ProminentNumberField(
                                    caption: "Min",
                                    value: $settings.randomMoveMinSeconds,
                                    width: 76
                                )
                                Text("–")
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(.tertiary)
                                    .padding(.bottom, 6)
                                ProminentNumberField(
                                    caption: "Max",
                                    value: $settings.randomMoveMaxSeconds,
                                    width: 76
                                )
                                Text("seconds")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 6)
                                Spacer(minLength: 0)
                            }
                        }
                    }

                    Text("Movement is always on once George is armed. Clicks and text stay off until you enable them on their tabs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GlassSectionLabel(title: "Sounds")
            GlassCard {
                Toggle(isOn: $settings.soundsEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ambient sounds")
                            .font(.headline)
                        Text("Typing bursts and the occasional hmm or throat-clear.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.large)
            }

            GlassSectionLabel(title: "Permissions")
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Accessibility")
                            .font(.headline)
                        Spacer()
                        Text(appState.isTrusted ? "Granted" : "Needed")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(appState.isTrusted ? Color.green : Color.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(
                                    (appState.isTrusted ? Color.green : Color.orange).opacity(0.16)
                                )
                            )
                    }
                    Text("If George isn’t listed, click + and add the app shown in Finder. Enable the checkbox, then relaunch. Leave George quit while you toggle it — a running copy can switch it back off.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Button("Open Accessibility Settings") {
                            AccessibilityPermission.openSystemSettings()
                        }
                        Button("Reveal in Finder") {
                            AccessibilityPermission.revealInFinder()
                        }
                        Button("Relaunch") {
                            AccessibilityPermission.relaunch()
                        }
                    }
                    .georgeGlassButton()
                    .controlSize(.regular)
                    Text("Panic hotkey: Option-Shift-Esc")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

private struct ClicksSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        SettingsStack {
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $settings.clicksEnabled) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Enable clicks")
                                .font(.headline)
                            Text("Clicks only happen at positions you pick. Nothing is clicked at random.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .controlSize(.large)

                    ActionCadenceRow(
                        everyNMoves: $settings.actionEveryNMoves,
                        enabled: settings.clicksEnabled,
                        verb: "Click",
                        otherFeatureOn: settings.textEnabled,
                        otherName: "text",
                        whenAlone: "After this many wander moves, George clicks one of your targets."
                    )
                    .disabled(!settings.clicksEnabled)

                    Picker("When several targets", selection: $settings.clickOrder) {
                        ForEach(SelectionOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                    .disabled(!settings.clicksEnabled)
                }
            }

            GlassSectionLabel(title: "Targets")
            if settings.clickTargets.isEmpty {
                GlassCard {
                    Text("No click targets yet.")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach($settings.clickTargets) { $target in
                GlassCard {
                    ClickTargetEditor(target: $target) {
                        settings.clickTargets.removeAll { $0.id == target.id }
                    }
                    .disabled(!settings.clicksEnabled)
                }
            }
            Button("Add click target") {
                settings.addClickTarget()
            }
            .georgeGlassProminentButton()
            .disabled(!settings.clicksEnabled)
        }
    }
}

private struct ClickTargetEditor: View {
    @Binding var target: ClickTarget
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Toggle(isOn: $target.enabled) { EmptyView() }
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                ProminentTextField(placeholder: "Name", text: $target.name)
                Stepper(value: $target.clickCount, in: 1...10) {
                    Text("\(target.clickCount) click\(target.clickCount == 1 ? "" : "s")")
                        .font(.body.weight(.medium).monospacedDigit())
                        .frame(minWidth: 78, alignment: .trailing)
                }
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            PositionRow(hasPosition: target.hasPosition, point: target.point) {
                Task {
                    if let point = await PositionPicker.pick() {
                        target.x = point.x
                        target.y = point.y
                        target.hasPosition = true
                    }
                }
            }
        }
    }
}

private struct TextSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        SettingsStack {
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $settings.textEnabled) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Enable text actions")
                                .font(.headline)
                            Text("Each action clicks the spot you marked, pastes a phrase, then optionally presses Enter.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .controlSize(.large)

                    ActionCadenceRow(
                        everyNMoves: $settings.actionEveryNMoves,
                        enabled: settings.textEnabled,
                        verb: "Paste",
                        otherFeatureOn: settings.clicksEnabled,
                        otherName: "clicks",
                        whenAlone: "After this many wander moves, George pastes at a text target."
                    )
                    .disabled(!settings.textEnabled)

                    Picker("When several actions", selection: $settings.textActionOrder) {
                        ForEach(SelectionOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                    .disabled(!settings.textEnabled)
                }
            }

            GlassSectionLabel(title: "Actions")
            if settings.textActions.isEmpty {
                GlassCard {
                    Text("No text actions yet.")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach($settings.textActions) { $action in
                GlassCard {
                    TextActionEditor(action: $action) {
                        settings.textActions.removeAll { $0.id == action.id }
                    }
                    .disabled(!settings.textEnabled)
                }
            }
            Button("Add text action") {
                settings.addTextAction()
            }
            .georgeGlassProminentButton()
            .disabled(!settings.textEnabled)
        }
    }
}

private struct TextActionEditor: View {
    @Binding var action: TextAction
    var onDelete: () -> Void
    @FocusState private var phrasesFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Toggle(isOn: $action.enabled) { EmptyView() }
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                ProminentTextField(placeholder: "Name", text: $action.name)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            PositionRow(hasPosition: action.hasPosition, point: action.point) {
                Task {
                    if let point = await PositionPicker.pick() {
                        action.x = point.x
                        action.y = point.y
                        action.hasPosition = true
                    }
                }
            }
            Picker("Phrase order", selection: $action.phraseOrder) {
                ForEach(SelectionOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
            Toggle("Press Enter after paste", isOn: $action.pressEnter)
            Text("Phrases (one per line)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextEditor(text: $action.phrasesText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 100)
                .focused($phrasesFocused)
                .modifier(FieldSurface(cornerRadius: 12, isFocused: phrasesFocused))
        }
    }
}

private struct ActionCadenceRow: View {
    @Binding var everyNMoves: Int
    let enabled: Bool
    let verb: String
    let otherFeatureOn: Bool
    let otherName: String
    let whenAlone: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(verb) after every")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 12) {
                ProminentNumberField(value: $everyNMoves, width: 76)
                Text("mouse moves")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
                Spacer(minLength: 0)
            }
            Text(helper)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(enabled ? 1 : 0.45)
    }

    private var helper: String {
        if otherFeatureOn {
            return "Shared with \(otherName). George does one click or paste when the count is reached."
        }
        return whenAlone
    }
}

private struct PositionRow: View {
    let hasPosition: Bool
    let point: CGPoint
    let onPick: () -> Void

    var body: some View {
        HStack {
            if hasPosition {
                Text(String(format: "x %.0f   y %.0f", point.x, point.y))
                    .font(.system(.body, design: .monospaced).weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.primary.opacity(0.08))
                    )
            } else {
                Text("No position set")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(hasPosition ? "Re-pick…" : "Pick position…", action: onPick)
                .georgeGlassButton()
        }
    }
}
