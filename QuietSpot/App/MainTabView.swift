//
//  MainTabView.swift
//  QuietSpot
//

import SwiftUI

struct MainTabView: View {
    let onSignOut: () -> Void
    @State private var cafes = CafeSampleData.cafes
    @State private var insights = CommunitySampleData.insights

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

            CommunityView(cafes: $cafes, insights: $insights)
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }

            CafeMapView(cafes: $cafes)
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            ProfileView(onSignOut: onSignOut)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(AppColor.accent)
    }
}

#Preview {
    MainTabView(onSignOut: {})
}
