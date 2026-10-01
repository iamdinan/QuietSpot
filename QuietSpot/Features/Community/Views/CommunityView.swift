import SwiftUI

struct CommunityView: View {
    @Binding var cafes: [CafeSnapshot]
    @Binding var insights: [CafeInsight]
    @State private var isComposing = false

    private var favorites: [CafeSnapshot] {
        cafes.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Text("Little discoveries from fellow café-goers.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if favorites.isEmpty {
                        Label("Save a café to your favorites to share an insight about it.", systemImage: "heart")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if insights.isEmpty {
                        ContentUnavailableView("No insights yet", systemImage: "text.bubble", description: Text("Share something you enjoyed about a favorite café."))
                    }

                    ForEach(insights.sorted { $0.createdAt > $1.createdAt }) { insight in
                        if let cafe = cafes.first(where: { $0.id == insight.cafeID }) {
                            CafeInsightCard(insight: insight, cafe: cafe)
                        }
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
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
                    insights.insert(CafeInsight(cafeID: cafeID, authorName: "You", text: text, createdAt: .now), at: 0)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let index = cafes.firstIndex(where: { $0.id == id }) {
                    CafeDetailsView(cafe: $cafes[index])
                }
            }
        }
    }
}

#Preview {
    CommunityView(cafes: .constant(CafeSampleData.cafes), insights: .constant(CommunitySampleData.insights))
}
