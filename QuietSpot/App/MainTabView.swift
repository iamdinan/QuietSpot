//
//  MainTabView.swift
//  QuietSpot
//

import SwiftUI

struct MainTabView: View {
    let onSignOut: () -> Void
    @State private var cafeViewModel = CafeViewModel()
    @State private var community = CommunityViewModel()
    @State private var cafeNotifications = CafeUpdateNotificationMonitor()
    @StateObject private var location = LocationProvider()
    @AppStorage("mapRadiusKilometers") private var radius = 5.0
    @AppStorage("cafeUpdatesEnabled") private var cafeUpdatesEnabled = true
    @Environment(\.scenePhase) private var scenePhase
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

            CafeMapView(cafes: $cafeData.cafes, location: location)
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
        .onChange(of: widgetContent, initial: true) { _, content in
            PulseWidgetPublisher.publish(content)
        }
        .onChange(of: communitySiriSnapshot, initial: true) { _, snapshot in
            snapshot.save()
        }
        .task {
            refreshNotificationContext()
            cafeViewModel.onConfirmedStatusChange = { [cafeNotifications] cafe, report in
                cafeNotifications.receive(cafe: cafe, latest: report)
            }
            if scenePhase == .active && cafeUpdatesEnabled { location.start(requestPermission: false) }
            if let userID = authentication.userID { community.start(userID: userID) }
            cafeViewModel.updateFavorites(authentication.favoriteCafeIDs)
            await cafeViewModel.load()
        }
        .onChange(of: authentication.favoriteCafeIDs) { _, ids in
            cafeViewModel.updateFavorites(ids)
            refreshNotificationContext()
        }
        .onChange(of: authentication.isUserDataReady) { refreshNotificationContext() }
        .onChange(of: location.currentLocation) { refreshNotificationContext() }
        .onChange(of: radius) { refreshNotificationContext() }
        .onChange(of: cafeUpdatesEnabled) {
            if cafeUpdatesEnabled && scenePhase == .active { location.start(requestPermission: false) }
            refreshNotificationContext()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                location.start(requestPermission: false)
            } else {
                location.stop()
            }
            refreshNotificationContext()
        }
        .onDisappear {
            location.stop()
            cafeNotifications.stop()
            cafeViewModel.onConfirmedStatusChange = nil
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

    private func refreshNotificationContext() {
        cafeNotifications.updateContext(
            userID: authentication.userID,
            favoriteIDs: authentication.favoriteCafeIDs,
            location: location.currentLocation,
            radiusKilometers: radius,
            enabled: cafeUpdatesEnabled && authentication.isUserDataReady && scenePhase == .active
        )
    }

    private var widgetContent: PulseWidgetContent {
        guard authentication.isUserDataReady else { return PulseWidgetContent(state: .loading) }
        if !authentication.favoriteCafeIDs.isEmpty && cafeViewModel.cafes.isEmpty {
            return PulseWidgetContent(state: cafeViewModel.errorMessage == nil ? .loading : .unavailable)
        }
        return PulseWidgetPublisher.content(cafes: cafeViewModel.cafes)
    }

    private var communitySiriSnapshot: CommunityPostSiriSnapshot {
        guard authentication.userID != nil else { return CommunityPostSiriSnapshot(state: .signedOut) }
        guard authentication.isUserDataReady else { return CommunityPostSiriSnapshot(state: .loading) }
        return CommunityPostSiriSnapshot.content(
            posts: community.insights, cafes: cafeViewModel.cafes,
            isLoading: community.isLoading, hasError: community.loadingError != nil
        )
    }
}

#Preview {
    MainTabView(onSignOut: {}, profile: .constant(UserProfile()))
        .environment(AuthenticationViewModel())
        .environment(\.loadsCafeImages, false)
}
