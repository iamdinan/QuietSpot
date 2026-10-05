import Foundation
import Testing
@testable import QuietSpot

@Suite("Community Siri snapshots")
@MainActor
struct CommunitySnapshotTests {
    @Test("Selects the newest post from unordered input and resolves café and author")
    func newestPost() {
        let newest = Fixtures.post(id: "new", offset: -300)
        let content = CommunityPostSiriSnapshot.content(posts: [Fixtures.post(id: "old", offset: -600), newest],
            cafes: [Fixtures.cafe()], isLoading: false, hasError: false)
        #expect(content.state == .ready)
        #expect(content.text == newest.text)
        #expect(content.author == "Alex")
        #expect(content.cafeName == "Test Café")
        #expect(content.createdAt == newest.createdAt)
        let response = content.message(now: Fixtures.now, locale: Fixtures.locale)
        #expect(response.contains("Alex shared about Test Café"))
        #expect(response.contains("5 minutes ago"))
        #expect(response.contains(newest.text))
        #expect(response.contains("Latest saved"))
    }

    @Test("Loading and error states clear stale post details")
    func loadingAndFailure() {
        let posts = [Fixtures.post()]
        let loading = CommunityPostSiriSnapshot.content(posts: posts, cafes: [], isLoading: true, hasError: true)
        #expect(loading.state == .loading && loading.text == nil)
        let failed = CommunityPostSiriSnapshot.content(posts: posts, cafes: [], isLoading: false, hasError: true)
        #expect(failed.state == .unavailable && failed.text == nil)
        #expect(loading.message().contains("still loading"))
        #expect(failed.message().contains("couldn’t be loaded"))
        #expect(CommunityPostSiriSnapshot(state: .signedOut).message().contains("sign in"))
    }

    @Test("Empty and incomplete posts use a safe empty-state response", arguments: ["empty", "blank", "undated"])
    func incompletePost(kind: String) {
        let content = CommunityPostSiriSnapshot(state: .ready,
            text: kind == "empty" ? nil : kind == "blank" ? " \n " : "An insight",
            createdAt: kind == "undated" ? nil : Fixtures.now)
        #expect(content.message().contains("no saved community posts"))
    }

    @Test("Missing café or author metadata has readable fallbacks")
    func missingMetadata() {
        let content = CommunityPostSiriSnapshot(state: .ready, text: "A tip", createdAt: Fixtures.now)
        #expect(content.message(now: Fixtures.now, locale: Fixtures.locale).contains("A café member shared about a café"))
        let noCafe = CommunityPostSiriSnapshot.content(posts: [Fixtures.post(cafeID: "missing")],
            cafes: [], isLoading: false, hasError: false)
        #expect(noCafe.cafeName == nil)
        let empty = CommunityPostSiriSnapshot.content(posts: [], cafes: [], isLoading: false, hasError: false)
        #expect(empty.state == .ready && empty.text == nil)
    }

    @Test("Author edits are reflected in newly generated snapshots")
    func authorUpdate() {
        var post = Fixtures.post()
        let original = CommunityPostSiriSnapshot.content(posts: [post], cafes: [], isLoading: false, hasError: false)
        post.authorName = "Updated author"
        let updated = CommunityPostSiriSnapshot.content(posts: [post], cafes: [], isLoading: false, hasError: false)
        #expect(original != updated)
        #expect(updated.author == "Updated author")
    }

    @Test("Snapshot JSON round-trips without losing post fields")
    func codableRoundTrip() throws {
        let original = CommunityPostSiriSnapshot.content(posts: [Fixtures.post()], cafes: [Fixtures.cafe()],
                                                       isLoading: false, hasError: false)
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(CommunityPostSiriSnapshot.self, from: data) == original)
    }
}
