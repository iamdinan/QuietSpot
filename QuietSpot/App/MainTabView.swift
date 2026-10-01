//
//  MainTabView.swift
//  QuietSpot
//

import SwiftUI

struct MainTabView: View {
    let onSignOut: () -> Void

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }

            TabPlaceholderView(title: "Community", icon: "person.3")
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }

            MapPreviewView()
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

private struct TabPlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: icon, description: Text("Coming next."))
        }
    }
}

#Preview {
    MainTabView(onSignOut: {})
}
