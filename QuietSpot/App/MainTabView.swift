//
//  MainTabView.swift
//  QuietSpot
//

import SwiftUI

struct MainTabView: View {
    let onSignOut: () -> Void
    @State private var cafeViewModel = CafeViewModel()
    @State private var community = CommunityViewModel()
    @Binding var profile: UserProfile
    @Environment(AuthenticationViewModel.self) private var authentication

    var body: some View {
        @Bindable var cafeData = cafeViewModel
        TabView {
            HomeView(cafes: $cafeData.cafes, onRefresh: { await cafeViewModel.load() })
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ExploreView(cafes: $cafeData.cafes)
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }

            CommunityView(cafes: $cafeData.cafes, profile: profile)
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }

            CafeMapView(cafes: $cafeData.cafes)
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            ProfileView(cafes: $cafeData.cafes, profile: $profile, onSignOut: onSignOut)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(AppColor.accent)
        .environment(community)
        .task {
            if let userID = authentication.userID { community.start(userID: userID) }
            cafeViewModel.updateFavorites(authentication.favoriteCafeIDs)
            await cafeViewModel.load()
        }
        .onChange(of: authentication.favoriteCafeIDs) { _, ids in
            cafeViewModel.updateFavorites(ids)
        }
        .overlay {
            if cafeViewModel.isLoading && cafeViewModel.cafes.isEmpty {
                ProgressView("Loading cafés…")
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .top) {
            if !authentication.isUserDataReady && authentication.userDataError == nil {
                ProgressView("Loading your profile and favourites…")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
            }
            if let error = authentication.userDataError {
                VStack(alignment: .leading, spacing: 8) {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                    Button("Try again", action: authentication.retryUserData)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
            }
            if let errorMessage = cafeViewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                    Button("Try again") { Task { await cafeViewModel.load() } }
                        .disabled(cafeViewModel.isLoading)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
            }
        }
    }
}

#Preview {
    MainTabView(onSignOut: {}, profile: .constant(UserProfile()))
        .environment(AuthenticationViewModel())
        .environment(\.loadsCafeImages, false)
}
