import SwiftUI

struct CommunityView: View {
    @Binding var cafes: [CafeSnapshot]
    @Binding var insights: [CafeInsight]
    let profile: UserProfile
    @State private var isComposing = false

    private var favorites: [CafeSnapshot] {
        cafes.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            CafeInsightFeed(
                cafes: $cafes,
                insights: $insights,
                profile: profile,
                intro: "Insights are saved for this session. Online community sharing is coming later.",
                notice: favorites.isEmpty ? "Save a café to your favorites to share an insight about it." : nil
            )
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share an insight", systemImage: "square.and.pencil") {
                        isComposing = true
                    }
                    .disabled(favorites.isEmpty)
                }
            }
            .sheet(isPresented: $isComposing) {
                InsightComposerView(favorites: favorites) { cafeID, text in
                    insights.insert(CafeInsight(cafeID: cafeID, authorName: profile.displayName, text: text, createdAt: .now, authorID: profile.id), at: 0)
                }
            }
        }
    }
}

#Preview {
    CommunityView(cafes: .constant(CafeSampleData.cafes), insights: .constant(CommunitySampleData.insights), profile: UserProfile())
}
