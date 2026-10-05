import SwiftUI

struct CommunityView: View {
    @Binding var cafes: [CafeSnapshot]
    @Environment(AuthenticationViewModel.self) private var authentication
    let profile: UserProfile
    @State private var isComposing = false

    private var favorites: [CafeSnapshot] {
        cafes.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            CafeInsightFeed(
                cafes: $cafes,
                profile: profile,
                intro: "Discover tips and experiences shared by the café community.",
                notice: favorites.isEmpty ? "Save a café to your favorites to share an insight about it." : nil
            )
            .tabScreenTitle("Community", systemImage: "person.3")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share an insight", systemImage: "square.and.pencil") {
                        isComposing = true
                    }
                    .disabled(NetworkStatus.shared.isOffline || favorites.isEmpty || !authentication.isUserDataReady)
                }
            }
            .sheet(isPresented: $isComposing) {
                InsightComposerView(favorites: favorites)
                    .presentationSizing(.form)
            }
        }
    }
}

#Preview {
    CommunityView(cafes: .constant([]), profile: UserProfile())
        .environment(CommunityViewModel())
        .environment(AuthenticationViewModel())
}
