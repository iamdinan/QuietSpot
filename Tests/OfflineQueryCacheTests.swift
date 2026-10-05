import Foundation

@main
struct OfflineQueryCacheTests {
    static func main() {
        let suite = "QuietSpot.OfflineTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = OfflineQueryCache(defaults: defaults)

        // Unknown empty caches must not be presented as authoritative empty lists.
        assert(!cache.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: true))
        assert(cache.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: false))
        assert(!cache.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: true))

        // Remember a server-confirmed empty list across cache helper instances.
        assert(cache.canUseSnapshot(key: "cafes", isFromCache: false, isEmpty: true))
        let relaunched = OfflineQueryCache(defaults: defaults)
        assert(relaunched.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: true))

        // Once the server has reports, an empty cache might reflect eviction, not no reports.
        assert(cache.canUseSnapshot(key: "cafes", isFromCache: false, isEmpty: false))
        assert(!cache.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: true))

        // Private query state cannot carry over into another account or café.
        assert(cache.canUseSnapshot(key: "favorites/alice", isFromCache: false, isEmpty: true))
        assert(cache.canUseSnapshot(key: "favorites/alice", isFromCache: true, isEmpty: true))
        assert(!cache.canUseSnapshot(key: "favorites/bob", isFromCache: true, isEmpty: true))
        assert(!cache.canUseSnapshot(key: "checkIns/cafeA", isFromCache: true, isEmpty: true))
        assert(cache.canUseSnapshot(key: "checkIns/cafeB", isFromCache: false, isEmpty: true))
        assert(!cache.canUseSnapshot(key: "checkIns/cafeA", isFromCache: true, isEmpty: true))
        print("Offline cache availability checks passed")
    }
}
