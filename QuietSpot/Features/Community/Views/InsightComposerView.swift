import SwiftUI

struct InsightComposerView: View {
    let favorites: [CafeSnapshot]
    @Environment(CommunityViewModel.self) private var community
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCafeID: String?
    @State private var text = ""
    @State private var isConfirmingDiscard = false
    @State private var isSharing = false
    @State private var errorMessage: String?

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canShare: Bool {
        !trimmedText.isEmpty && trimmedText.count <= 2_000 && favorites.contains { $0.id == selectedCafeID } && !isSharing
    }

    init(favorites: [CafeSnapshot]) {
        self.favorites = favorites
        _selectedCafeID = State(initialValue: favorites.first?.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Café", selection: $selectedCafeID) {
                        ForEach(favorites) { cafe in
                            Text(cafe.name).tag(Optional(cafe.id))
                        }
                    }
                } header: {
                    Text("Your favorite café")
                } footer: {
                    Text("Choose a café from your favorites.")
                }

                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("What would you like others to know?")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Your insight")
                } header: {
                    Text("Your insight")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if trimmedText.isEmpty {
                            Text("Write an insight to enable Share.")
                        }
                        if trimmedText.count > 2_000 {
                            Text("Keep your insight within 2,000 characters.")
                        }
                        Text("Share a useful tip or a little discovery. Your insight will be visible to the community.")
                    }
                }
            }
            .disabled(isSharing)
            .overlay {
                if isSharing {
                    ProgressView("Sharing insight…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Share an insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if text.isEmpty {
                            dismiss()
                        } else {
                            isConfirmingDiscard = true
                        }
                    }
                    .disabled(isSharing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        guard canShare, let cafeID = selectedCafeID else { return }
                        let insightText = trimmedText
                        let viewModel = community
                        isSharing = true
                        Task { @MainActor [cafeID, insightText, viewModel] in
                            defer { isSharing = false }
                            do {
                                try await viewModel.share(cafeID: cafeID, text: insightText)
                                dismiss()
                            } catch {
                                errorMessage = "Couldn’t share your insight. \(error.localizedDescription)"
                            }
                        }
                    }
                    .disabled(NetworkStatus.shared.isOffline || !canShare)
                }
            }
            .confirmationDialog("Discard this insight?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard insight", role: .destructive) { dismiss() }
                Button("Keep writing", role: .cancel) {}
            }
            .interactiveDismissDisabled(!text.isEmpty || isSharing)
            .alert("Insight wasn’t shared", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
            .onChange(of: favorites.map(\.id)) { _, ids in
                if let selectedCafeID, !ids.contains(selectedCafeID) {
                    self.selectedCafeID = ids.first
                }
            }
        }
    }
}
