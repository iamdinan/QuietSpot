import SwiftUI
import PhotosUI
import ImageIO

struct EditProfileView: View {
    @Binding var profile: UserProfile
    @Environment(AuthenticationViewModel.self) private var authentication
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var photoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var showsPhotoError = false
    @State private var showsDiscardConfirmation = false

    init(profile: Binding<UserProfile>) {
        _profile = profile
        _displayName = State(initialValue: profile.wrappedValue.displayName)
        _photoData = State(initialValue: profile.wrappedValue.photoData)
    }

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasChanges: Bool {
        displayName != profile.displayName || photoData != profile.photoData
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile photo") {
                    ProfileAvatar(photoData: photoData, size: 96)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(photoData == nil ? "Add photo" : "Change photo", systemImage: "photo")
                    }
                    .disabled(isLoadingPhoto)

                    if isLoadingPhoto {
                        ProgressView("Loading photo…")
                    }

                    if photoData != nil {
                        Button("Remove photo", role: .destructive) {
                            photoData = nil
                            selectedPhoto = nil
                        }
                        .disabled(isLoadingPhoto)
                    }
                }

                Section {
                    TextField("Display name", text: $displayName)
                        .textContentType(.nickname)
                        .submitLabel(.done)
                } header: {
                    Text("Display name")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if trimmedName.isEmpty {
                            Text("Enter a display name to save your profile.")
                        }
                        Text("Your name and photo appear on your community posts, including insights you’ve already shared.")
                    }
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            showsDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !trimmedName.isEmpty, !isLoadingPhoto, !authentication.isBusy else { return }
                        Task {
                            if trimmedName != profile.displayName {
                                guard await authentication.updateDisplayName(trimmedName) else { return }
                            }
                            profile.photoData = photoData
                            dismiss()
                        }
                    }
                    .disabled(trimmedName.isEmpty || isLoadingPhoto || authentication.isBusy || !hasChanges)
                }
            }
            .disabled(authentication.isBusy)
            .interactiveDismissDisabled(hasChanges || isLoadingPhoto || authentication.isBusy)
            .confirmationDialog("Discard profile changes?", isPresented: $showsDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
            .alert("Photo couldn’t be loaded", isPresented: $showsPhotoError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again or choose a different photo.")
            }
            .task(id: selectedPhoto) {
                await loadPhoto()
            }
        }
    }

    @MainActor
    private func loadPhoto() async {
        guard let selectedPhoto else { return }
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        do {
            let loadedData = try await selectedPhoto.loadTransferable(type: Data.self)
            guard !Task.isCancelled else { return }
            guard let data = loadedData else {
                showsPhotoError = true
                return
            }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 512,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
                  let resizedData = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.85) else {
                showsPhotoError = true
                return
            }
            photoData = resizedData
        } catch {
            if !Task.isCancelled { showsPhotoError = true }
        }
    }
}
