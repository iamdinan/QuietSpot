import SwiftUI

struct CafeInsightFeed: View {
    @Binding var cafes: [CafeSnapshot]
    @Environment(CommunityViewModel.self) private var community
    let profile: UserProfile
    var onlyCurrentUser = false
    let intro: String
    var notice: String? = nil

    private var visibleInsights: [CafeInsight] {
        community.insights
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

                if community.isLoading {
                    ProgressView("Loading insights…")
                        .frame(maxWidth: .infinity)
                }

                if let error = community.loadingError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                    Button("Try again", action: community.retry)
                }

                if visibleInsights.isEmpty && !community.isLoading && community.loadingError == nil {
                    ContentUnavailableView(
                        onlyCurrentUser ? "No insights shared yet" : "No insights yet",
                        systemImage: "text.bubble",
                        description: Text(onlyCurrentUser ? "Share an insight about a favorite café in Community. Your posts will appear here." : "Share something you enjoyed about a favorite café.")
                    )
                }

                ForEach(visibleInsights) { insight in
                    if let cafe = cafes.first(where: { $0.id == insight.cafeID }) {
                        CafeInsightCard(insight: insight, cafe: cafe, profile: profile, onToggleLike: {
                            Task { await community.toggleLike(insight) }
                        }, isLikeEnabled: community.loadedLikeIDs.contains(insight.id) && !community.savingLikeIDs.contains(insight.id))
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .alert("Community update", isPresented: Binding(
            get: { community.actionError != nil },
            set: { if !$0 { community.actionError = nil } }
        )) {
            Button("Try again") { community.actionError = nil; community.retry() }
            Button("OK", role: .cancel) { community.actionError = nil }
        } message: {
            Text(community.actionError ?? "Please try again.")
        }
        .navigationDestination(for: String.self) { id in
            if let index = cafes.firstIndex(where: { $0.id == id }) {
                CafeDetailsView(cafe: $cafes[index])
            }
        }
    }
}
