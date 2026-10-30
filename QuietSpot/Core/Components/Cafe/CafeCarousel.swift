// Scrolls compact cafe cards horizontally beneath a section heading.

import SwiftUI

struct CafeCarousel: View {
    let cafes: [CafeSnapshot]
    let accessibilityContext: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !cafes.isEmpty {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(cafes) { cafe in
                        NavigationLink(value: cafe.id) {
                            CompactCafeCard(cafe: cafe)
                                // Leave the next card visible to suggest horizontal scrolling.
                                .containerRelativeFrame(.horizontal) { width, _ in
                                    min(dynamicTypeSize.isAccessibilitySize ? 360 : 280, width * 0.85)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                // Measure the full row so every card can match the tallest content.
                .fixedSize(horizontal: false, vertical: true)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .accessibilityLabel(accessibilityContext)
        }
    }
}

private struct CompactCafeCard: View {
    let cafe: CafeSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear
                .aspectRatio(2, contentMode: .fit)
                .overlay { CafeImage(cafe: cafe) }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(cafe.name)
                    .font(.headline)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                Text(cafe.area)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if cafe.statusErrorMessage != nil {
                Label("Status unavailable", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            } else if cafe.isLoadingStatus {
                ProgressView("Loading status…")
            } else if let noiseLevel = cafe.noiseLevel {
                Label(noiseLevel.rawValue, systemImage: "speaker.wave.2")
                    .foregroundStyle(AppColor.accent)
                    .accessibilityLabel("Noise: \(noiseLevel.rawValue)")
            } else {
                Label("No check-ins yet", systemImage: "clock")
                    .foregroundStyle(.secondary)
            }

            if let updatedAt = cafe.updatedAt {
                CheckInTimeText(
                    date: cafe.recentCheckIns.first?.createdAt,
                    fallback: updatedAt, prefix: "Updated "
                )
                .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens café details")
    }
}
