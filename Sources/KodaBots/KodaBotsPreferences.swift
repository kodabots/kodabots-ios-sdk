import Foundation

public final class KodaBotsPreferences {

    // MARK: - Properties (public)

    public static let shared = KodaBotsPreferences()

    // MARK: - Properties (private)

    private let userPreferences = UserDefaults.standard

    // MARK: - Lifecycle (private)

    private init(){}
}

// MARK: - Methods

extension KodaBotsPreferences {
    func setUserId(userId: String?) {
        userPreferences.set(userId, forKey: K.userID)
    }

    func getUserId() -> String? {
        return userPreferences.string(forKey: K.userID)
    }

    func setCache(_ value: String?, forKey key: String) {
        var cache = getCache()
        cache[key] = value
        userPreferences.set(cache, forKey: K.webCache)
    }

    func getCache(forKey key: String) -> String? {
        return getCache()[key]
    }

    func clearCache() {
        userPreferences.removeObject(forKey: K.webCache)
    }

    private func getCache() -> [String: String] {
        return userPreferences.dictionary(forKey: K.webCache) as? [String: String] ?? [:]
    }
}

// MARK: - Cosntants (private)

private enum K {
    static let userID = "KEY_USER_ID"
    static let webCache = "KEY_WEB_CACHE"
}
