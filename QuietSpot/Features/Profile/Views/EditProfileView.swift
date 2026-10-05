import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Binding var profile: UserProfile
    @Environment(AuthenticationViewModel.self) private var authentication
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditProfileViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showsDiscardConfirmation = false

    init(profile: Binding<UserProfile>) {
        _profile = profile
        _viewModel = State(initialValue: EditProfileViewModel(profile: profile.wrappedValue))
    }

    private var hasChanges: Bool {
        viewModel.hasChanges(comparedTo: profile)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        let photoButtonTitle: LocalizedStringKey = viewModel.photoData == nil ? "Add photo" : "Change photo"
        NavigationStack {
            Form {
                Section("Profile photo") {
                    ProfileAvatar(photoData: viewModel.photoData, size: 96)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(photoButtonTitle, systemImage: "photo")
                    }
                    .disabled(viewModel.isLoadingPhoto)

                    if viewModel.isLoadingPhoto {
                        ProgressView("Loading photo…")
                    }

                    if viewModel.photoData != nil {
                        Button("Remove photo", role: .destructive) {
                            viewModel.photoData = nil
                            selectedPhoto = nil
                        }
                        .disabled(viewModel.isLoadingPhoto)
                    }
                }

                Section {
                    TextField("Display name", text: $viewModel.displayName)
                        .textContentType(.nickname)
                        .submitLabel(.done)
                } header: {
                    Text("Display name")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if viewModel.trimmedName.isEmpty {
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
                        Task {
                            if await viewModel.save(using: authentication) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.trimmedName.isEmpty || viewModel.isLoadingPhoto || authentication.isBusy || !authentication.isUserDataReady || !hasChanges)
                }
            }
            .disabled(authentication.isBusy)
            .interactiveDismissDisabled(hasChanges || viewModel.isLoadingPhoto || authentication.isBusy)
            .confirmationDialog("Discard profile changes?", isPresented: $showsDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
            .alert("Photo couldn’t be loaded", isPresented: Binding(
                get: { viewModel.photoErrorMessage != nil },
                set: { if !$0 { viewModel.photoErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.photoErrorMessage = nil }
            } message: {
                Text(viewModel.photoErrorMessage ?? "Please try again.")
            }
            .task(id: selectedPhoto) {
                await viewModel.loadPhoto(selectedPhoto)
            }
        }
    }
}
