//
//  HomeView.swift
//  QuietSpot
//

import SwiftUI

struct HomeView: View {
    private let cafes = HomeSampleData.favoriteCafes

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 32) {
                    LivePulseWidget(cafes: Array(cafes.prefix(3)))
                    latestStatusSection
                    favoritesSection
                    recentUpdatesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Home")
        }
    }

    private var latestStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Latest check-ins", subtitle: "Updates from your favorite cafés")

            VStack(spacing: 10) {
                ForEach(cafes.prefix(3)) { cafe in
                    CafeStatusCard(cafe: cafe, showsDetails: false)
                }
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your favorite cafés", subtitle: "5 saved places")
            FavoriteCafesPager(cafes: cafes)
        }
    }

    private var recentUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent updates", subtitle: "From cafés you follow")

            VStack(spacing: 10) {
                ForEach(cafes) { cafe in
                    CafeStatusCard(cafe: cafe, showsDetails: true)
                }
            }
        }
    }
}

private struct LivePulseWidget: View {
    let cafes: [CafeSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Live pulse", systemImage: "dot.radiowaves.left.and.right")
                        .font(.headline)
                        .foregroundStyle(AppColor.accent)
                    Text("Your favorite cafés, right now")
                        .font(.title3.bold())
                }

                Spacer()

                Text("Fresh")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.14), in: Capsule())
            }

            VStack(spacing: 0) {
                ForEach(Array(cafes.enumerated()), id: \.element.id) { index, cafe in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(noiseColor(for: cafe.noiseLevel))
                            .frame(width: 9, height: 9)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cafe.name)
                                .font(.subheadline.weight(.semibold))
                            Text(cafe.area)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(cafe.noiseLevel.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(noiseColor(for: cafe.noiseLevel))
                    }
                    .padding(.vertical, 11)

                    if index < cafes.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func noiseColor(for level: NoiseLevel) -> Color {
        switch level {
        case .quiet: .green
        case .moderate: .orange
        case .loud: .red
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HomeView()
}
