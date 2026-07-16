import SwiftUI

/// Data Backup sheet (Quit Porn → Privacy). Export shares the latest snapshot
/// at Documents/rewire-state.json; Import decodes a picked file and restores
/// all stores after a destructive confirm. Mirrors ReminderSettingsView's
/// sheet chrome (drag capsule + title).
struct DataBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showImporter = false
    @State private var pickedURL: URL?
    @State private var showImportConfirm = false
    @State private var showImportFailed = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            SheetChrome(title: "Data Backup")

            VStack(spacing: Theme.Spacing.md) {
                Text("Export your progress to a file you can save or share. Importing a backup replaces everything currently on this device.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                ShareLink(item: PersistenceController.shared.backupURL) {
                    PrimaryButtonLabel(title: "Export Backup")
                }
                .buttonStyle(PressableButtonStyle())
                .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })

                Button {
                    Haptics.tap()
                    showImporter = true
                } label: {
                    Text("Import Backup")
                        .font(Theme.Typography.button())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Theme.Colors.surface3, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            }
            .screenPadding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.background)
        .onAppear { PersistenceController.shared.flush() }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                pickedURL = url
                showImportConfirm = true
            }
        }
        .rewireAlert(isPresented: showImportConfirm) {
            RewireAlert(
                title: "Import Backup",
                message: "This replaces all current progress on this device with the backup file. This can't be undone.",
                cancelTitle: "Cancel",
                confirmTitle: "Import",
                onCancel: { showImportConfirm = false },
                onConfirm: {
                    showImportConfirm = false
                    importPicked()
                }
            )
        }
        .rewireAlert(isPresented: showImportFailed) {
            RewireAlert(
                title: "Import Failed",
                message: "Couldn't read that backup file.",
                confirmTitle: "OK",
                confirmIsDestructive: false,
                onCancel: { showImportFailed = false },
                onConfirm: { showImportFailed = false }
            )
        }
    }

    private func importPicked() {
        guard let url = pickedURL else { showImportFailed = true; return }
        guard url.startAccessingSecurityScopedResource() else {
            showImportFailed = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            let snapshot = try PersistenceController.decode(data)
            PersistenceController.shared.restoreAll(from: snapshot)
            Haptics.success()
            dismiss()
        } catch {
            showImportFailed = true
        }
    }
}

#Preview { DataBackupView() }
