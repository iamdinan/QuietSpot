import Foundation

struct CommunityPostSiriSnapshot: Codable, Equatable {
    enum State: String, Codable { case signedOut, loading, ready, unavailable }
    var state: State
    var text: String? = nil
    var author: String? = nil
    var cafeName: String? = nil
    var createdAt: Date? = nil
    private static let key = "communityPostSiriSnapshot"

    static func load() -> Self? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }

    func save() {
        guard Self.load() != self, let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    static func content(posts: [CafeInsight], cafes: [CafeSnapshot], isLoading: Bool, hasError: Bool) -> Self {
        guard !isLoading else { return Self(state: .loading) }
        guard !hasError else { return Self(state: .unavailable) }
        guard let post = posts.max(by: { $0.createdAt < $1.createdAt }) else { return Self(state: .ready) }
        return Self(state: .ready, text: post.text, author: post.authorName,
                    cafeName: cafes.first { $0.id == post.cafeID }?.name, createdAt: post.createdAt)
    }

    func message(now: Date = .now, locale: Locale = .current) -> String {
        switch state {
        case .signedOut: return "Please sign in to QuietSpot to read community posts."
        case .loading: return "Community posts are still loading. Open QuietSpot to finish syncing."
        case .unavailable: return "Community posts couldn’t be loaded. Open QuietSpot to try again."
        case .ready: break
        }
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let createdAt else { return "There are no saved community posts yet. Open QuietSpot to refresh." }
        let age = CafeCheckInTimeFormatter.string(from: createdAt, relativeTo: now, locale: locale)
        return "Latest saved community post: \(author ?? "A café member") shared about \(cafeName ?? "a café"), \(age): \(text). Open QuietSpot to refresh."
    }
}
