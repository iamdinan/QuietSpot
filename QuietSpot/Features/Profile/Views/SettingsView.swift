import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @Environment(\.scenePhase) private var scenePhase
    @State private var biometricName = "Biometrics"
    @State private var biometricStatus = "Unavailable"

    var body: some View {
        Form {
            Section("Preferences") {
                Picker("Appearance", selection: $appearanceMode) {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                        Text(appearance.title).tag(appearance.rawValue)
                    }
                }

                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Notifications", systemImage: "bell")
                }
            }

            Section {
                MapRadiusControl()
            } header: {
                Text("Map")
            } footer: {
                Text("Set your nearby café radius. You can also adjust this directly in Map.")
            }

            Section {
                LabeledContent(biometricName, value: biometricStatus)
            } header: {
                Text("Security")
            } footer: {
                Text("Device authentication is managed in iOS Settings. App unlocking with biometrics is not enabled in QuietSpot yet.")
            }

            Section {
                NavigationLink {
                    AboutQuietSpotView()
                } label: {
                    Label("About QuietSpot", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshBiometrics)
        .onChange(of: scenePhase) {
            if scenePhase == .active { refreshBiometrics() }
        }
    }

    private func refreshBiometrics() {
        let context = LAContext()
        let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: biometricName = "Face ID"
        case .touchID: biometricName = "Touch ID"
        case .opticID: biometricName = "Optic ID"
        case .none: biometricName = "Biometrics"
        @unknown default: biometricName = "Biometrics"
        }
        biometricStatus = isAvailable ? "Available on this device" : "Unavailable"
    }
}

private struct AboutQuietSpotView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("QuietSpot")
                        .font(.title3.bold())
                    Text("Find cafés that fit your pace.")
                        .foregroundStyle(.secondary)
                    Text("Version 1.0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("About QuietSpot")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
