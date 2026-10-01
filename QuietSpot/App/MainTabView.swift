//
//  MainTabView.swift
//  QuietSpot
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            TabPlaceholderView(title: "Explore", icon: "safari")
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }

            TabPlaceholderView(title: "Community", icon: "person.3")
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }

            TabPlaceholderView(title: "Map", icon: "map")
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            TabPlaceholderView(title: "Profile", icon: "person")
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
    MainTabView()
}
