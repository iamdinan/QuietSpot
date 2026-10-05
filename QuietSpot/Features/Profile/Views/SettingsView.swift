import SwiftUI

struct SettingsView: View {
    @Environment(AuthenticationViewModel.self) private var authentication
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Form {
            Section("Preferences") {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Notifications", systemImage: "bell")
                }

                NavigationLink {
                    AccessibilitySettingsView()
                } label: {
                    Label("Accessibility", systemImage: "accessibility")
                }
            }

            Section {
                Toggle(isOn: Binding(
                    get: { authentication.faceIDEnabled },
                    set: { authentication.setFaceIDEnabled($0) }
                )) {
                    Label("Face ID", systemImage: "faceid")
                }
                .disabled(authentication.isBusy || (!authentication.faceIDAvailable && !authentication.faceIDEnabled))
            } header: {
                Text("Security")
            } footer: {
                Text(authentication.faceIDMessage)
            }

            Section {
                NavigationLink {
                    AboutQuietSpotView()
                } label: {
                    Label("About QuietSpot", systemImage: "info.circle")
                }
            }
        }
        .readableGroupedContent()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authentication.refreshFaceID() }
        .onChange(of: scenePhase) {
            if scenePhase == .active { authentication.refreshFaceID() }
        }
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
        .readableGroupedContent()
        .navigationTitle("About QuietSpot")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthenticationViewModel())
}
