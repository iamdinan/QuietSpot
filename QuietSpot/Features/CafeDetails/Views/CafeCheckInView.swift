import SwiftUI

struct CafeCheckInView: View {
    let cafe: CafeSnapshot
    let onSubmit: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noise: NoiseLevel = .quiet
    @State private var wifi = "Strong Wi‑Fi"
    @State private var outlets = "Outlets free"
    @State private var crowd = "Uncrowded"
    @State private var viewModel = CafeCheckInViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(cafe.name).font(.headline)
                    Text("What are the conditions right now?")
                        .foregroundStyle(.secondary)
                }
                Section("Café conditions") {
                    Picker("Noise", selection: $noise) {
                        ForEach(NoiseLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    Picker("Wi‑Fi", selection: $wifi) {
                        Text("Strong Wi‑Fi").tag("Strong Wi‑Fi")
                        Text("Spotty Wi‑Fi").tag("Spotty Wi‑Fi")
                    }
                    Picker("Outlets", selection: $outlets) {
                        Text("Outlets free").tag("Outlets free")
                        Text("Outlets full").tag("Outlets full")
                    }
                    Picker("Crowd", selection: $crowd) {
                        Text("Uncrowded").tag("Uncrowded")
                        Text("Crowded").tag("Crowded")
                    }
                }
            }
            .readableGroupedContent()
            .disabled(viewModel.isSubmitting)
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isSubmitting)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if viewModel.isSubmitting {
                        ProgressView("Waiting for Firebase to confirm your check-in…")
                            .font(.footnote)
                    }
                    PrimaryButton(viewModel.isSubmitting ? "Saving…" : "Submit check-in") {
                        Task {
                            if await viewModel.submit(cafeID: cafe.id, noise: noise, wifi: wifi, outlets: outlets, crowd: crowd) {
                                onSubmit()
                                dismiss()
                            }
                        }
                    }
                    .disabled(NetworkStatus.shared.isOffline || viewModel.isSubmitting)
                }
                .padding()
                .readableContent()
                .background(.bar)
            }
            .tint(AppColor.accent)
            .interactiveDismissDisabled(viewModel.isSubmitting)
            .alert("Couldn’t save check-in", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "Please try again.")
            }
        }
    }
}
