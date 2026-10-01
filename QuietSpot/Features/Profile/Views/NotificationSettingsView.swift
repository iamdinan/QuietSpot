import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage("cafeUpdatesEnabled") private var cafeUpdatesEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var authorization: UNAuthorizationStatus?
    @State private var isRequesting = false
    @State private var errorMessage: String?

    private var canReceiveNotifications: Bool {
        authorization == .authorized || authorization == .provisional || authorization == .ephemeral
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("iOS permission", value: authorizationLabel)
                if authorization == .notDetermined {
                    Button("Allow notifications") {
                        Task { await requestPermission() }
                    }
                    .disabled(isRequesting)
                } else if authorization != nil {
                    Button("Open notification settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
                if isRequesting { ProgressView("Requesting permission…") }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.secondary)
                }
            } header: {
                Text("System permission")
            } footer: {
                Text("Choose whether iOS allows QuietSpot notifications. You can change permission in iOS Settings.")
            }

            Section {
                Toggle("Café updates", isOn: Binding(
                    get: { canReceiveNotifications && cafeUpdatesEnabled },
                    set: { cafeUpdatesEnabled = $0 }
                ))
                .disabled(!canReceiveNotifications)
            } header: {
                Text("Notification preferences")
            } footer: {
                Text("Receive updates about your favorite cafés when notification permission is allowed.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppColor.accent)
        .task { await refreshPermission() }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await refreshPermission() }
            }
        }
    }

    private var authorizationLabel: String {
        switch authorization {
        case .authorized: "Allowed"
        case .provisional: "Quiet delivery"
        case .ephemeral: "Temporarily allowed"
        case .denied: "Not allowed"
        case .notDetermined: "Not requested"
        case nil: "Checking…"
        @unknown default: "Unknown"
        }
    }

    private func refreshPermission() async {
        authorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func requestPermission() async {
        isRequesting = true
        errorMessage = nil
        defer { isRequesting = false }
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            await refreshPermission()
        } catch {
            errorMessage = "Notification permission couldn’t be requested. Please try again."
        }
    }
}

#Preview {
    NavigationStack { NotificationSettingsView() }
}
