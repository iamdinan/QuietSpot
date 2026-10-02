import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage("cafeUpdatesEnabled") private var cafeUpdatesEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var viewModel = NotificationSettingsViewModel()

    var body: some View {
        Form {
            Section {
                LabeledContent("iOS permission", value: viewModel.authorizationLabel)
                if viewModel.authorization == .notDetermined {
                    Button("Allow notifications") {
                        Task { await viewModel.requestPermission() }
                    }
                    .disabled(viewModel.isRequesting)
                } else if viewModel.authorization != nil {
                    Button("Open notification settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
                if viewModel.isRequesting { ProgressView("Requesting permission…") }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.secondary)
                }
            } header: {
                Text("System permission")
            } footer: {
                Text("Choose whether iOS allows QuietSpot notifications. You can change permission in iOS Settings.")
            }

            Section {
                Toggle("Café updates", isOn: Binding(
                    get: { viewModel.canReceiveNotifications && cafeUpdatesEnabled },
                    set: { cafeUpdatesEnabled = $0 }
                ))
                .disabled(!viewModel.canReceiveNotifications)
            } header: {
                Text("Notification preferences")
            } footer: {
                Text("Receive updates about your favorite cafés when notification permission is allowed.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppColor.accent)
        .task { await viewModel.refreshPermission() }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await viewModel.refreshPermission() }
            }
        }
    }
}

#Preview {
    NavigationStack { NotificationSettingsView() }
}
