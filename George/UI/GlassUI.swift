import AppKit
import SwiftUI

struct VisualEffectBackdrop: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(GlassSurface(cornerRadius: cornerRadius))
    }
}

struct GlassSurface: ViewModifier {
    var cornerRadius: CGFloat = 16
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(.thinMaterial, in: shape)
                .overlay(
                    shape.strokeBorder(
                        Color.white.opacity(colorScheme == .dark ? 0.14 : 0.35),
                        lineWidth: 1
                    )
                )
        }
    }
}

struct FieldSurface: ViewModifier {
    var cornerRadius: CGFloat = 12
    var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(
                shape.fill(Color.primary.opacity(colorScheme == .dark ? 0.22 : 0.08))
            )
            .overlay(
                shape.strokeBorder(
                    isFocused
                        ? Color.accentColor.opacity(0.95)
                        : Color.primary.opacity(colorScheme == .dark ? 0.42 : 0.22),
                    lineWidth: isFocused ? 1.6 : 1
                )
            )
    }
}

struct ProminentNumberField: View {
    var caption: String?
    @Binding var value: Double
    var width: CGFloat = 84
    var range: ClosedRange<Double> = 1...86_400

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let caption {
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                stepButton("minus") {
                    value = max(range.lowerBound, (value - 1).rounded())
                }
                TextField("", value: $value, format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .focused($isFocused)
                    .frame(width: width, height: 40)
                    .modifier(FieldSurface(isFocused: isFocused))
                stepButton("plus") {
                    value = min(range.upperBound, (value + 1).rounded())
                }
            }
        }
    }

    private func stepButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(Circle().fill(Color.primary.opacity(0.1)))
        .accessibilityLabel(systemName == "plus" ? "Increase" : "Decrease")
    }
}

extension ProminentNumberField {
    init(
        caption: String? = nil,
        value: Binding<Int>,
        width: CGFloat = 84,
        range: ClosedRange<Int> = 1...9_999
    ) {
        self.caption = caption
        self.width = width
        self.range = Double(range.lowerBound)...Double(range.upperBound)
        self._value = Binding(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = Int($0.rounded()) }
        )
    }
}

struct ProminentTextField: View {
    var placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.body.weight(.medium))
            .padding(.horizontal, 12)
            .frame(height: 36)
            .focused($isFocused)
            .modifier(FieldSurface(cornerRadius: 10, isFocused: isFocused))
    }
}

struct GlassSectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.horizontal, 4)
    }
}

extension View {
    func georgeGlassButton() -> some View {
        modifier(GeorgeGlassButton())
    }
}

private struct GeorgeGlassButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

extension View {
    func georgeGlassProminentButton() -> some View {
        modifier(GeorgeGlassProminentButton())
    }
}

private struct GeorgeGlassProminentButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}
