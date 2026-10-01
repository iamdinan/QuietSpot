import SwiftUI

struct CafeCheckInView: View {
    let cafe: CafeSnapshot
    let onSubmit: (CafeCheckIn) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noise: NoiseLevel = .quiet
    @State private var wifi = "Strong Wi‑Fi"
    @State private var outlets = "Outlets free"
    @State private var crowd = "Uncrowded"

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
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton("Submit check-in") {
                    onSubmit(CafeCheckIn(time: "Just now", noiseLevel: noise, wifi: wifi, outlets: outlets, crowd: crowd))
                    dismiss()
                }
                .padding()
                .background(.bar)
            }
            .tint(AppColor.accent)
        }
    }
}
