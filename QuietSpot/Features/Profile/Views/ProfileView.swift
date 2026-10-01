import SwiftUI

struct ProfileView: View {
    @Binding var cafes: [CafeSnapshot]
    @Binding var insights: [CafeInsight]
    @Binding var profile: UserProfile
    let onSignOut: () -> Void
    @State private var showsSignOutConfirmation = false
    @State private var showsEditProfile = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        ProfileAvatar(photoData: profile.photoData, size: 72)

                        VStack(spacing: 4) {
                            Text(profile.displayName)
                                .font(.title2.bold())
                            Text("Your café discoveries, in one place.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        Button("Edit profile") {
                            showsEditProfile = true
                        }
                        .buttonStyle(.borderless)
                        .frame(minHeight: 44)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("Community") {
                    NavigationLink {
                        MyInsightsView(cafes: $cafes, insights: $insights, profile: profile)
                    } label: {
                        HStack {
                            Label("My insights", systemImage: "text.bubble")
                            Spacer()
                            Text(insights.filter { $0.authorID == profile.id }.count, format: .number)
                                .foregroundStyle(.secondary)
                        }
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
            .sheet(isPresented: $showsEditProfile) {
                EditProfileView(profile: $profile)
            }
            .confirmationDialog("Sign out of QuietSpot?", isPresented: $showsSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign out", role: .destructive, action: onSignOut)
            } message: {
                Text("You’ll need to sign in again to access your account.")
            }
        }
    }
}

#Preview {
    ProfileView(cafes: .constant(CafeSampleData.cafes), insights: .constant(CommunitySampleData.insights), profile: .constant(UserProfile()), onSignOut: {})
        .environment(AuthenticationViewModel())
}
