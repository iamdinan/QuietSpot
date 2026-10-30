// Shows the favorite pulse and carousels of saved and nearby cafes.

import SwiftUI
import CoreLocation

struct HomeView: View {
    @Binding var cafes: [CafeSnapshot]
    @ObservedObject var location: LocationProvider
    @AppStorage("mapRadiusKilometers") private var radius = 5.0
    @Environment(\.openURL) private var openURL
    var onRefresh: (() async -> Void)? = nil

    private var favorites: [CafeSnapshot] { cafes.filter(\.isFavorite) }
    private var latestFavorites: [CafeSnapshot] {
        Array(favorites.sorted(by: CafeSnapshot.latestFirst).prefix(3))
    }

    // Distance is in meters, while the saved radius is in kilometers.
    private var nearbyCafes: [CafeSnapshot] {
        guard let userLocation = location.currentLocation else { return [] }
        return cafes.filter {
            userLocation.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <= radius * 1000
        }.sorted(by: CafeSnapshot.latestFirst)
    }

    private var nearbyEmptyMessage: String {
        if location.permissionDenied { return "Allow location access to find cafés near you." }
        if let message = location.errorMessage { return message }
        if location.currentLocation == nil { return "Enable location or wait for your location to find nearby cafés." }
        return "No cafés within \(Int(radius)) km. Try a larger radius in Map."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    LivePulseWidget(cafes: latestFavorites)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Your favorite cafés", subtitle: "Saved for this session", count: favorites.count)
                        if favorites.isEmpty {
                            Text("Tap the heart on a café's details page to save it.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        CafeCarousel(cafes: favorites, accessibilityContext: "Favorite cafés")
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Near you", subtitle: "Within your map radius of \(Int(radius)) km", count: nearbyCafes.count)
                        if nearbyCafes.isEmpty {
                            Text(nearbyEmptyMessage)
                                .font(.subheadline).foregroundStyle(.secondary)
                            if location.currentLocation == nil {
                                Button(location.permissionDenied ? "Open location settings" : "Find my location") {
                                    if location.permissionDenied {
                                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                                    } else {
                                        location.start()
                                    }
                                }
                            }
                        }
                        CafeCarousel(cafes: nearbyCafes, accessibilityContext: "Nearby cafés")
                    }
                }
                .padding(20)
                .readableContent()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .refreshable { await onRefresh?() }
            .tabScreenTitle("Home", systemImage: "house")
            .onAppear { location.start(requestPermission: false) }
            .navigationDestination(for: String.self) { cafeID in
                if let index = cafes.firstIndex(where: { $0.id == cafeID }) {
                    CafeDetailsView(cafe: $cafes[index])
                }
            }
        }
    }
}

private struct LivePulseWidget: View {
    let cafes: [CafeSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Favorite café pulse", systemImage: "waveform.path")
                    .font(.title3.bold())
                    .foregroundStyle(AppColor.accent)
                Text(cafes.isEmpty ? "Save a café using the heart on its details page" : "Latest updates from \(cafes.count) of your favorites")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            ForEach(Array(cafes.enumerated()), id: \.element.id) { index, cafe in
                if index > 0 { Divider() }
                NavigationLink(value: cafe.id) {
                    CafeStatusCard(cafe: cafe, style: .widget)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(AppColor.accent.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title3.bold())
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(10)
                .background(Color(uiColor: .tertiarySystemFill), in: Circle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(count) cafés. \(subtitle)")
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    HomeView(cafes: .constant([]), location: LocationProvider())
}
