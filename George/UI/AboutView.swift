import SwiftUI

struct LegalTextSheet: View {
    let title: String
    let text: String
    var monospaced = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .georgeGlassProminentButton()
            }

            TextEditor(text: .constant(text))
                .font(monospaced ? .system(size: 12, design: .monospaced) : .body)
                .scrollContentBackground(.hidden)
                .textSelection(.enabled)
                .frame(minHeight: 280)
                .padding(8)
                .modifier(FieldSurface(isFocused: false))
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 420)
    }
}

struct AboutView: View {
    @State private var legalSheet: LegalSheetKind?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(nsImage: GeorgeBrand.appIcon())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(GeorgeBrand.name)
                        .font(.title2.weight(.bold))
                    Text(GeorgeBrand.tagline)
                        .foregroundStyle(.secondary)
                    Text(GeorgeBrand.copyright)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(GeorgeBrand.disclaimer)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button("View license…") {
                    legalSheet = .license
                }
                .georgeGlassButton()
                Button("Legal notice / Impressum…") {
                    legalSheet = .imprint
                }
                .georgeGlassButton()
                Spacer(minLength: 0)
            }
        }
        .padding(22)
        .frame(width: 480)
        .background(VisualEffectBackdrop().ignoresSafeArea())
        .sheet(item: $legalSheet) { sheet in
            switch sheet {
            case .license:
                LegalTextSheet(title: "License", text: GeorgeBrand.licenseText, monospaced: true)
            case .imprint:
                LegalTextSheet(title: "Legal notice / Impressum", text: GeorgeBrand.imprintText)
            }
        }
    }
}

private enum LegalSheetKind: String, Identifiable {
    case license
    case imprint
    var id: String { rawValue }
}
