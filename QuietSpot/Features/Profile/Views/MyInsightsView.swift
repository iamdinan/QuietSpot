import SwiftUI

struct MyInsightsView: View {
    @Binding var cafes: [CafeSnapshot]
    @Binding var insights: [CafeInsight]
    let profile: UserProfile

    var body: some View {
        CafeInsightFeed(
            cafes: $cafes,
            insights: $insights,
            profile: profile,
            onlyCurrentUser: true,
            intro: "The café insights you’ve shared with the community."
        )
        .navigationTitle("My insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}
