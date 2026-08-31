import SwiftUI

/// Manage the two exception lists on top of Apple's filter: sites vouched for
/// after a false positive, and sites blocked because the list missed them.
///
/// The asymmetry is the point and the UI has to show it. Vouching for a site
/// weakens the blocker, so a running commitment refuses it; blocking one
/// strengthens it and is always allowed. Users learn that rule from watching
/// the screen behave, not from a paragraph.
struct SiteExceptionsView: View {
    @Environment(ShieldController.self) private var guardController
    @Environment(\.dismiss) private var dismiss

    @State private var allowInput = ""
    @State private var blockInput = ""
    /// Inline, per-field feedback — a silently ignored entry is the failure
    /// mode this whole screen exists to prevent.
    @State private var allowError: String?
    @State private var blockError: String?

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Site exceptions", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    allowedSection
                    blockedSection
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
            .collapsesDock()
        }
        .background { SceneBackground(kind: .void) }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Sections

    private var allowedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            eyebrow("Always allowed")
            Text("Sites you've vouched for. The filter lets these through.")
                .font(Theme.Typography.label())
                .foregroundStyle(Theme.Colors.textLo)
                .fixedSize(horizontal: false, vertical: true)

            if guardController.isBound {
                lockedNote("A commitment is running, so you can't allow new sites until it ends. You can still block more.")
            } else {
                field(text: $allowInput, placeholder: "example.com", error: $allowError) {
                    switch guardController.allow(allowInput) {
                    case .ok:            allowInput = ""; allowError = nil; Haptics.success()
                    case .invalidDomain: allowError = "That doesn't look like a website address."
                    case .locked:        allowError = "A commitment is running."
                    }
                }
            }

            if guardController.allowedDomains.isEmpty {
                emptyNote("Nothing allowed yet.")
            } else {
                VStack(spacing: 10) {
                    ForEach(guardController.allowedDomains.sorted(), id: \.self) { domain in
                        // Removing a vouch strengthens the blocker, so it's
                        // never gated by the commitment.
                        row(domain, action: "Remove") {
                            guardController.removeAllowed(domain)
                            Haptics.tap()
                        }
                    }
                }
            }
        }
    }

    private var blockedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            eyebrow("Also blocked")
            Text("Blocked on top of Apple's list, for anything it misses.")
                .font(Theme.Typography.label())
                .foregroundStyle(Theme.Colors.textLo)
                .fixedSize(horizontal: false, vertical: true)

            field(text: $blockInput, placeholder: "example.com", error: $blockError) {
                switch guardController.block(blockInput) {
                case .ok:            blockInput = ""; blockError = nil; Haptics.success()
                case .invalidDomain: blockError = "That doesn't look like a website address."
                case .locked:        blockError = "A commitment is running."
                }
            }

            if guardController.blockedDomains.isEmpty {
                emptyNote("Nothing extra blocked.")
            } else {
                VStack(spacing: 10) {
                    ForEach(guardController.blockedDomains.sorted(), id: \.self) { domain in
                        row(domain,
                            action: guardController.isBound ? "Locked" : "Remove",
                            disabled: guardController.isBound) {
                            guardController.removeBlocked(domain)
                            Haptics.tap()
                        }
                    }
                }
            }
        }
    }

    // MARK: Kit

    private func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Theme.Typography.caption())
            .tracking(1.4)
            .foregroundStyle(Theme.Colors.textXlo)
    }

    /// Dropdown-pill geometry: 56pt capsule, opaque carbon, with the add action
    /// riding on the right.
    private func field(text: Binding<String>, placeholder: String,
                       error: Binding<String?>, submit: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: Theme.Spacing.sm) {
                TextField("", text: text,
                          prompt: Text(placeholder).foregroundColor(Theme.Colors.textXlo))
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textHi)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.done)
                    .onSubmit(submit)

                Button(action: submit) {
                    Text("Add")
                        .font(Theme.Typography.button())
                        .foregroundStyle(text.wrappedValue.isEmpty
                                         ? Theme.Colors.textXlo : Theme.Colors.butter)
                }
                .disabled(text.wrappedValue.isEmpty)
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color(hex: 0x161618), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))

            if let message = error.wrappedValue {
                Text(message)
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.critical)
            }
        }
    }

    private func row(_ domain: String, action: String, disabled: Bool = false,
                     onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Text(domain)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textHi)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
            Button(action: onTap) {
                Text(action)
                    .font(Theme.Typography.label())
                    .foregroundStyle(disabled ? Theme.Colors.textXlo : Theme.Colors.textLo)
            }
            .disabled(disabled)
        }
        .padding(.horizontal, 20)
        .frame(height: 62)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
    }

    private func lockedNote(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.butter)
            Text(text)
                .font(Theme.Typography.label())
                .foregroundStyle(Theme.Colors.textLo)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private func emptyNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.Colors.textXlo)
    }
}
