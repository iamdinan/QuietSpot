import Foundation

@main
struct CommunityPostSiriTests {
    @MainActor
    static func main() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let locale = Locale(identifier: "en_US_POSIX")
        let cafe = CafeSnapshot(id: "cafe", name: "Barista", area: "Colombo", description: "", latitude: 6.9, longitude: 79.8)
        let old = CafeInsight(id: "old", cafeID: "cafe", text: "Older post", createdAt: now.addingTimeInterval(-600), authorID: "old-author")
        let newest = CafeInsight(id: "new", cafeID: "cafe", authorName: "Asha", text: "A quiet spot with good Wi-Fi", createdAt: now.addingTimeInterval(-300), authorID: "new-author")
        let snapshot = CommunityPostSiriSnapshot.content(posts: [old, newest], cafes: [cafe], isLoading: false, hasError: false)
        assert(snapshot.text == newest.text, "Select the newest date, not the first array element")
        let response = snapshot.message(now: now, locale: locale)
        for text in ["Latest saved", "Asha", "Barista", newest.text, "5 minutes ago", "Open QuietSpot to refresh"] {
            assert(response.contains(text), "Missing spoken detail: \(text)")
        }
        assert(!response.contains(old.text))
        assert(snapshot.message(now: now.addingTimeInterval(300), locale: locale).contains("10 minutes ago"))
        let decoded = try JSONDecoder().decode(CommunityPostSiriSnapshot.self, from: JSONEncoder().encode(snapshot))
        assert(decoded == snapshot)
        assert(CommunityPostSiriSnapshot(state: .signedOut).message().contains("sign in"))
        assert(CommunityPostSiriSnapshot(state: .signedOut).text == nil, "Signing out clears the saved text")
        assert(CommunityPostSiriSnapshot(state: .loading).text == nil, "New accounts start without old data")
        assert(CommunityPostSiriSnapshot.content(posts: [newest], cafes: [cafe], isLoading: true, hasError: false).message().contains("still loading"))
        assert(CommunityPostSiriSnapshot.content(posts: [newest], cafes: [cafe], isLoading: false, hasError: true).message().contains("couldn’t be loaded"))
        assert(CommunityPostSiriSnapshot.content(posts: [], cafes: [cafe], isLoading: false, hasError: false).message().contains("no saved community posts"))
        let missingCafe = CommunityPostSiriSnapshot.content(posts: [newest], cafes: [], isLoading: false, hasError: false)
        assert(missingCafe.message(now: now, locale: locale).contains("about a café"))
        var edited = newest
        edited.authorName = "New Name"
        assert(CommunityPostSiriSnapshot.content(posts: [edited], cafes: [cafe], isLoading: false, hasError: false).author == "New Name")
        print("Community post Siri regression checks passed")
    }
}
