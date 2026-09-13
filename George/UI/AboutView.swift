import SwiftUI

struct LicenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("License")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .georgeGlassProminentButton()
            }

            TextEditor(text: .constant(GeorgeBrand.licenseText))
                .font(.system(size: 12, design: .monospaced))
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
    @State private var showingLicense = false

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
                }
            }

            Text(GeorgeBrand.disclaimer)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("View license…") {
                    showingLicense = true
                }
                .georgeGlassButton()
                Spacer()
            }
        }
        .padding(22)
        .frame(width: 440)
        .background(VisualEffectBackdrop().ignoresSafeArea())
        .sheet(isPresented: $showingLicense) {
            LicenseSheet()
        }
    }
}
