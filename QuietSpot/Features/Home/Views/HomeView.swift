import SwiftUI

struct HomeView: View {
    @Binding var cafes: [CafeSnapshot]

    private var favorites: [CafeSnapshot] { cafes.filter(\.isFavorite) }
    private var latestFavorites: [CafeSnapshot] {
        Array(favorites.sorted { $0.updateOrder < $1.updateOrder }.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    LivePulseWidget(cafes: latestFavorites)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Your favorite cafés", subtitle: "Your saved places", count: favorites.count)
                        CafePager(cafes: favorites)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "All cafés", subtitle: "Latest check-ins across every café", count: cafes.count)
                        CafePager(cafes: cafes.sorted { $0.updateOrder < $1.updateOrder })
                    }
                }
                .padding(20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Home")
            .navigationDestination(for: UUID.self) { cafeID in
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
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview { HomeView(cafes: .constant(CafeSampleData.cafes)) }
