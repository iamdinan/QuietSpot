import Testing
@testable import QuietSpot

@Suite("Offline query availability")
@MainActor
struct OfflineCacheTests {
    @Test("An unknown empty cache is unavailable, while downloaded records can be used")
    func unknownCache() throws {
        let storage = try TestStorage()
        defer { storage.cleanUp() }
        let cache = OfflineQueryCache(defaults: storage.defaults)
        #expect(!cache.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: true))
        #expect(cache.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: false))
        #expect(!cache.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: true))
    }

    @Test("A server-confirmed empty collection remains usable across instances")
    func confirmedEmptyCache() throws {
        let storage = try TestStorage()
        defer { storage.cleanUp() }
        let first = OfflineQueryCache(defaults: storage.defaults)
        #expect(first.canUseSnapshot(key: "cafes", isFromCache: false, isEmpty: true))
        let restored = OfflineQueryCache(defaults: storage.defaults)
        #expect(restored.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: true))
        #expect(restored.canUseSnapshot(key: "cafes", isFromCache: false, isEmpty: false))
        #expect(!restored.canUseSnapshot(key: "cafes", isFromCache: true, isEmpty: true))
    }

    @Test("Empty-cache confirmation cannot leak between accounts or cafés")
    func queryIsolation() throws {
        let storage = try TestStorage()
        defer { storage.cleanUp() }
        let cache = OfflineQueryCache(defaults: storage.defaults)
        #expect(cache.canUseSnapshot(key: "favorites/alex", isFromCache: false, isEmpty: true))
        #expect(cache.canUseSnapshot(key: "checkIns/a", isFromCache: false, isEmpty: true))
        #expect(!cache.canUseSnapshot(key: "favorites/sam", isFromCache: true, isEmpty: true))
        #expect(!cache.canUseSnapshot(key: "checkIns/b", isFromCache: true, isEmpty: true))
    }
}
