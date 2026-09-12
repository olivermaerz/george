import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 9, height: 9)
                    .shadow(color: statusColor.opacity(0.65), radius: 4)
                VStack(alignment: .leading, spacing: 1) {
                    Text(appState.runState.menuTitle)
                        .font(.headline)
                    Text(GeorgeBrand.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            if !appState.isTrusted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Open Accessibility, add \(GeorgeBrand.name) with +, enable it, then relaunch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    extraRow("Open Accessibility Settings") {
                        AccessibilityPermission.openSystemSettings()
                    }
                    extraRow("Reveal in Finder") {
                        AccessibilityPermission.revealInFinder()
                    }
                    extraRow("Relaunch") {
                        AccessibilityPermission.relaunch()
                    }
                }
            }

            TimelineView(.periodic(from: .now, by: 1)) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    ExtraActionButton(
                        title: appState.isArmed ? "Disarm" : "Arm",
                        subtitle: armSubtitle,
                        prominent: !appState.isArmed
                    ) {
                        appState.toggleArmed()
                    }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(!appState.isTrusted && !appState.isArmed)

                    if appState.runState != .running {
                        ExtraActionButton(
                            title: "Start immediately",
                            subtitle: "Skip the wait and start moving",
                            prominent: false
                        ) {
                            appState.startNow()
                        }
                        .keyboardShortcut(.return, modifiers: [.command])
                        .disabled(!appState.isTrusted)
                    }
                }
            }

            Toggle(isOn: $settings.soundsEnabled) {
                Text("Sounds")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .padding(.vertical, 2)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                extraRow("Settings…") {
                    appState.openSettings()
                }
                .keyboardShortcut(",", modifiers: [.command])
                extraRow("About") {
                    appState.showAbout()
                }
                extraRow("Quit") {
                    appState.disarm()
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }

            Text("Panic: Option-Shift-Esc")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(width: 280, alignment: .leading)
        .background(VisualEffectBackdrop(material: .hudWindow).ignoresSafeArea())
        .onAppear {
            appState.refreshTrust()
        }
    }

    private var idleSeconds: Int {
        max(1, Int(settings.idleTimeoutSeconds.rounded()))
    }

    private var armSubtitle: String {
        if appState.runState == .waiting {
            let remaining = appState.secondsUntilStart
            return remaining == 0 ? "Starting…" : "Starting in \(remaining)s"
        }
        if appState.isArmed {
            return "Waiting for inactivity"
        }
        let unit = idleSeconds == 1 ? "second" : "seconds"
        return "Activates after \(idleSeconds) \(unit) of inactivity"
    }

    private var statusColor: Color {
        switch appState.runState {
        case .off: return .secondary
        case .waiting: return .orange
        case .running: return .green
        }
    }

    private func extraRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ExtraActionButton: View {
    let title: String
    let subtitle: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
            .contentShape(Rectangle())
        }
        .controlSize(.large)
        .modifier(ExtraActionStyle(prominent: prominent))
    }
}

private struct ExtraActionStyle: ViewModifier {
    let prominent: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if prominent {
            content.georgeGlassProminentButton()
        } else {
            content.georgeGlassButton()
        }
    }
}

struct MenuBarLabel: View {
    let runState: RunState

    var body: some View {
        Image(nsImage: MenuBarGlyph.image(running: runState == .running))
            .renderingMode(.template)
            .help(GeorgeBrand.name)
    }
}
