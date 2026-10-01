import SwiftUI

struct CafeInsightFeed: View {
    @Binding var cafes: [CafeSnapshot]
    @Binding var insights: [CafeInsight]
    let profile: UserProfile
    var onlyCurrentUser = false
    let intro: String
    var notice: String? = nil

    private var visibleInsights: [CafeInsight] {
        insights
            .filter { insight in
                (!onlyCurrentUser || insight.authorID == profile.id) && cafes.contains { $0.id == insight.cafeID }
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let notice {
                    Label(notice, systemImage: "heart")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if visibleInsights.isEmpty {
                    ContentUnavailableView(
                        onlyCurrentUser ? "No insights shared yet" : "No insights yet",
                        systemImage: "text.bubble",
                        description: Text(onlyCurrentUser ? "Share an insight about a favorite café in Community. Your posts will appear here." : "Share something you enjoyed about a favorite café.")
                    )
                }

                ForEach(visibleInsights) { insight in
                    if let cafe = cafes.first(where: { $0.id == insight.cafeID }) {
                        CafeInsightCard(insight: insight, cafe: cafe, profile: profile) {
                            if let index = insights.firstIndex(where: { $0.id == insight.id }) {
                                insights[index].isLiked.toggle()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationDestination(for: UUID.self) { id in
            if let index = cafes.firstIndex(where: { $0.id == id }) {
                CafeDetailsView(cafe: $cafes[index])
            }
        }
    }
}
