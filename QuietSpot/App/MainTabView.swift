//
//  MainTabView.swift
//  QuietSpot
//

import SwiftUI

struct MainTabView: View {
    let onSignOut: () -> Void
    @State private var cafes = CafeSampleData.cafes
    @State private var insights = CommunitySampleData.insights
    @Binding var profile: UserProfile

    var body: some View {
        TabView {
            HomeView(cafes: $cafes)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ExploreView(cafes: $cafes)
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }

            CommunityView(cafes: $cafes, insights: $insights, profile: profile)
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }

            CafeMapView(cafes: $cafes)
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            ProfileView(cafes: $cafes, insights: $insights, profile: $profile, onSignOut: onSignOut)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(AppColor.accent)
    }
}

#Preview {
    MainTabView(onSignOut: {}, profile: .constant(UserProfile()))
        .environment(AuthenticationViewModel())
}
