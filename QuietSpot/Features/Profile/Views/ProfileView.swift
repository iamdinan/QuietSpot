import SwiftUI

struct ProfileView: View {
    let onSignOut: () -> Void
    @State private var showsSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProfilePreviewView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(AppColor.accent)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Your profile")
                                    .font(.headline)
                                Text("View your account details")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showsSignOutConfirmation = true
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog("Sign out of QuietSpot?", isPresented: $showsSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign out", role: .destructive, action: onSignOut)
            } message: {
                Text("You’ll need to sign in again to access your account.")
            }
        }
    }
}

private struct ProfilePreviewView: View {
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 68))
                        .foregroundStyle(AppColor.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your profile")
                            .font(.title3.bold())
                        Text("Account details will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Profile preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView(onSignOut: {})
}
