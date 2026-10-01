import SwiftUI

struct InsightComposerView: View {
    let favorites: [CafeSnapshot]
    let onShare: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCafeID: String?
    @State private var text = ""
    @State private var isConfirmingDiscard = false

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canShare: Bool {
        !trimmedText.isEmpty && favorites.contains { $0.id == selectedCafeID }
    }

    init(favorites: [CafeSnapshot], onShare: @escaping (String, String) -> Void) {
        self.favorites = favorites
        self.onShare = onShare
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
                        Text("Share a useful tip or a little discovery. Your insight will be visible to the community.")
                    }
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        guard canShare, let selectedCafeID else { return }
                        onShare(selectedCafeID, trimmedText)
                        dismiss()
                    }
                    .disabled(!canShare)
                }
            }
            .confirmationDialog("Discard this insight?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard insight", role: .destructive) { dismiss() }
                Button("Keep writing", role: .cancel) {}
            }
            .interactiveDismissDisabled(!text.isEmpty)
            .onChange(of: favorites.map(\.id)) { _, ids in
                if let selectedCafeID, !ids.contains(selectedCafeID) {
                    self.selectedCafeID = ids.first
                }
            }
        }
    }
}
