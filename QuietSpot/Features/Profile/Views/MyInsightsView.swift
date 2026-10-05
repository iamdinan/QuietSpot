import SwiftUI

struct MyInsightsView: View {
    @Binding var cafes: [CafeSnapshot]
    let profile: UserProfile

    var body: some View {
        CafeInsightFeed(
            cafes: $cafes,
            profile: profile,
            onlyCurrentUser: true,
            intro: "The café insights you’ve shared with the community."
        )
        .navigationTitle("My insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}
