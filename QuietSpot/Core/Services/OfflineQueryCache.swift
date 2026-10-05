import Foundation

/// An empty local query can mean either no saved data or a confirmed empty collection.
/// Store only that distinction; Firestore stores the documents themselves.
struct OfflineQueryCache {
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func canUseSnapshot(key: String, isFromCache: Bool, isEmpty: Bool) -> Bool {
        let storageKey = "offlineEmptyQuery." + key
        if !isFromCache {
            defaults.set(isEmpty, forKey: storageKey)
            return true
        }
        return !isEmpty || defaults.bool(forKey: storageKey)
    }
}
