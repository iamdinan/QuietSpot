import SwiftUI

struct ExploreView: View {
    @State private var cafes = CafeSampleData.cafes
    @State private var searchText = ""
    @State private var activeFilters = Set<PositiveCafeFilter>()

    private var filteredCafes: [CafeSnapshot] {
        cafes.filter { cafe in
            let matchesSearch = searchText.isEmpty
                || cafe.name.localizedCaseInsensitiveContains(searchText)
                || cafe.area.localizedCaseInsensitiveContains(searchText)
            let matchesFilters = activeFilters.allSatisfy { $0.matches(cafe) }
            return matchesSearch && matchesFilters
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredCafes.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            Text("\(filteredCafes.count) café\(filteredCafes.count == 1 ? "" : "s") available")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            CafePager(cafes: filteredCafes, pageSize: 5)
                        }
                        .padding(20)
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Explore")
            .searchable(text: $searchText, prompt: "Search cafés or areas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(PositiveCafeFilter.allCases) { filter in
                            Toggle(isOn: filterBinding(for: filter)) {
                                Label(filter.title, systemImage: filter.icon)
                            }
                        }

                        if !activeFilters.isEmpty {
                            Divider()
                            Button("Clear filters", role: .destructive) {
                                activeFilters.removeAll()
                            }
                        }
                    } label: {
                        Label(
                            activeFilters.isEmpty ? "Filters" : "\(activeFilters.count) filters",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                    .accessibilityLabel("Filter cafés")
                }
            }
            .navigationDestination(for: UUID.self) { cafeID in
                if let index = cafes.firstIndex(where: { $0.id == cafeID }) {
                    CafeDetailsView(cafe: $cafes[index])
                }
            }
        }
    }

    private func filterBinding(for filter: PositiveCafeFilter) -> Binding<Bool> {
        Binding(
            get: { activeFilters.contains(filter) },
            set: { isActive in
                if isActive {
                    activeFilters.insert(filter)
                } else {
                    activeFilters.remove(filter)
                }
            }
        )
    }
}

private enum PositiveCafeFilter: CaseIterable, Hashable, Identifiable {
    case quiet
    case strongWiFi
    case outletsFree
    case uncrowded

    var id: Self { self }

    var title: String {
        switch self {
        case .quiet: "Quiet"
        case .strongWiFi: "Strong Wi‑Fi"
        case .outletsFree: "Outlets free"
        case .uncrowded: "Uncrowded"
        }
    }

    var icon: String {
        switch self {
        case .quiet: "speaker.wave.2"
        case .strongWiFi: "wifi"
        case .outletsFree: "powerplug"
        case .uncrowded: "person.2"
        }
    }

    func matches(_ cafe: CafeSnapshot) -> Bool {
        switch self {
        case .quiet: cafe.noiseLevel == .quiet
        case .strongWiFi: cafe.wifi == "Strong Wi‑Fi"
        case .outletsFree: cafe.outlets == "Outlets free"
        case .uncrowded: cafe.crowd == "Uncrowded"
        }
    }
}

#Preview {
    ExploreView()
}
