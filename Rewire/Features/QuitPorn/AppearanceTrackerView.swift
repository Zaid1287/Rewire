import SwiftUI
import PhotosUI

/// Appearance Tracker (Quit Porn → Willpower → "Appearance Tracker"): a daily
/// photo journal. Pushed full-screen (not a sheet) since the grid wants room.
/// Photos are stored on disk via AppState; only the filename/date are
/// persisted. First saved photo unlocks the "Appearance Booster" badge
/// (BadgeProgress reads `gems.achievements.contains("appearance")`).
struct AppearanceTrackerView: View {
    @Environment(AppState.self) private var appState
    @Environment(GemStore.self) private var gems
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedPhoto: AppearancePhoto?
    @State private var showDeleteConfirm = false

    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.sm),
                            GridItem(.flexible(), spacing: Theme.Spacing.sm),
                            GridItem(.flexible(), spacing: Theme.Spacing.sm)]

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(title: "Appearance Tracker", showsBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    photosPickerButton

                    if appState.appearancePhotos.isEmpty {
                        Text("Track how your appearance improves as you stay clean — snap a quick photo each day and watch the progress add up.")
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, Theme.Spacing.xxl)
                    } else {
                        LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                            // Already newest-first: addAppearancePhoto inserts at index 0.
                            ForEach(appState.appearancePhotos) { photo in
                                photoCell(photo)
                            }
                        }
                    }
                }
                .screenPadding()
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.tabBarClearance)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    appState.addAppearancePhoto(image)
                    gems.recordAchievement("appearance")
                }
                pickerItem = nil
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            photoDetail(photo)
        }
    }

    private var photosPickerButton: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            PrimaryButtonLabel(title: "Add Today's Photo")
        }
        .buttonStyle(PressableButtonStyle())
        .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })
    }

    private func photoCell(_ photo: AppearancePhoto) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            thumbnail(photo)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                .contentShape(Rectangle())
                .onTapGesture {
                    Haptics.tap()
                    selectedPhoto = photo
                }
            Text(photo.date.formatted(date: .abbreviated, time: .omitted))
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    @ViewBuilder
    private func thumbnail(_ photo: AppearancePhoto) -> some View {
        if let uiImage = UIImage(contentsOfFile: AppState.appearancePhotoURL(photo.filename).path) {
            Image(uiImage: uiImage).resizable()
        } else {
            Theme.Colors.surface2
        }
    }

    private func photoDetail(_ photo: AppearancePhoto) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack {
                Spacer()
                Button {
                    Haptics.tap()
                    selectedPhoto = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(Theme.Spacing.md)

            Spacer()
            thumbnail(photo)
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                .screenPadding()
            Text(photo.date.formatted(date: .abbreviated, time: .omitted))
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()

            Button {
                Haptics.tap()
                showDeleteConfirm = true
            } label: {
                Text("Delete Photo")
                    .font(Theme.Typography.button())
                    .foregroundStyle(Theme.Colors.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Theme.Colors.surface3, in: Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .screenPadding()
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
        .overlay {
            if showDeleteConfirm {
                RewireAlert(
                    title: "Delete Photo",
                    message: "This photo will be permanently removed. This can't be undone.",
                    cancelTitle: "Cancel",
                    confirmTitle: "Delete",
                    onCancel: { showDeleteConfirm = false },
                    onConfirm: {
                        showDeleteConfirm = false
                        appState.deleteAppearancePhoto(photo)
                        selectedPhoto = nil
                    }
                )
            }
        }
    }
}

#Preview {
    AppearanceTrackerView().environment(AppState()).environment(GemStore())
}
