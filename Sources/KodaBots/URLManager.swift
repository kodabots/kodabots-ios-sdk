import Foundation

public class URLManager {

    // MARK: - Properties (public)

    public static let shared = URLManager()

    public var type: KBServerType = .release

    // MARK: - Properties

    var base: String {
        switch type {
        case .release:
            return K.Release.base
        case .stage:
            return K.Stage.base
        }
    }

    var baseVersion: String {
        switch type {
        case .release:
            return K.Release.baseVersion
        case .stage:
            return K.Stage.baseVersion
        }
    }

    var rest: String {
        switch type {
        case .release:
            return K.Release.rest
        case .stage:
            return K.Stage.rest
        }
    }

    var restVersion: String {
        switch type {
        case .release:
            return K.Release.restVersion
        case .stage:
            return K.Stage.restVersion
        }
    }

    // MARK: - Lifecycle (private)

    private init() {
        let plist = Bundle.main.object(forInfoDictionaryKey: K.infoDictionaryKey) as? [String:Any]
        guard let plist else { return }
        guard let server = plist[K.serverKey] as? String? else { return }
        if server == K.stageKey {
            type = .stage
        } else {
            type = .release
        }
    }
}

// MARK: - Constants (private)

private enum K {
    static let stageKey = "STAGE"
    static let serverKey = "server"
    static let infoDictionaryKey = "KodaBotsSDK"

    enum Release {
        static let base = "https://web.eu-pl.koda.ai"
        static let baseVersion = "v1"
        static let rest = "https://bot.eu-pl.koda.ai"
        static let restVersion = "v1"
    }

    enum Stage {
        static let base = "https://web.staging.koda.ai"
        static let baseVersion = "v1"
        static let rest = "https://bot.staging.koda.ai"
        static let restVersion = "v1"
    }
}
