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
}

// MARK: - Cosntants (private)

private enum K {
    static let userID = "KEY_USER_ID"
}
