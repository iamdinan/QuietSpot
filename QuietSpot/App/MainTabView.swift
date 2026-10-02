//
//  MainTabView.swift
//  QuietSpot
//

import SwiftUI

struct MainTabView: View {
    let onSignOut: () -> Void
    @State private var cafeViewModel = CafeViewModel()
    @State private var insights: [CafeInsight] = []
    @Binding var profile: UserProfile

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

            CommunityView(cafes: $cafeData.cafes, insights: $insights, profile: profile)
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }

            CafeMapView(cafes: $cafeData.cafes)
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            ProfileView(cafes: $cafeData.cafes, insights: $insights, profile: $profile, onSignOut: onSignOut)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(AppColor.accent)
        .task { await cafeViewModel.load() }
        .overlay {
            if cafeViewModel.isLoading && cafeViewModel.cafes.isEmpty {
                ProgressView("Loading cafés…")
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .top) {
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
