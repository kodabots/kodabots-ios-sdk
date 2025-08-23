import Foundation

public class URLManager {

	// MARK: - Properties (public)

	public static let shared = URLManager()

	public var type: KBServerType = .release

	// MARK: - Properties

	var overridenPath: KodaURL? = nil

	var base: String {
		guard shouldReturnDefaultPath() else { return overridenPath?.base ?? "" }
		switch type {
		case .release:
			return K.Release.base
		case .stage:
			return K.Stage.base
		}
	}

	var baseVersion: String {
		guard shouldReturnDefaultPath() else { return overridenPath?.baseVersion ?? "" }
		switch type {
		case .release:
			return K.Release.baseVersion
		case .stage:
			return K.Stage.baseVersion
		}
	}

	var rest: String {
		guard shouldReturnDefaultPath() else { return overridenPath?.rest ?? "" }
		switch type {
		case .release:
			return K.Release.rest
		case .stage:
			return K.Stage.rest
		}
	}

	var restVersion: String {
		guard shouldReturnDefaultPath() else { return overridenPath?.restVersion ?? "" }
		switch type {
		case .release:
			return K.Release.restVersion
		case .stage:
			return K.Stage.restVersion
		}
	}

	var unreadCounter: URL? {
		if restVersion.isEmpty {
			return URL(string:"\(URLManager.shared.rest)/sdk/unread-counter")
		} else {
			return URL(string:"\(URLManager.shared.rest)/sdk/\(URLManager.shared.restVersion)/unread-counter")
		}
	}

	func mobileToken(clientToken: String) -> URL? {
		if baseVersion.isEmpty {
			if clientToken.replacingOccurrences(of: " ", with: "").isEmpty {
				return URL(string: "\(base)/mobile")
			} else {
				return URL(string: "\(base)/mobile/?token=\(clientToken)")
			}
		} else {
			return URL(string: "\(base)/mobile/\(baseVersion)?token=\(clientToken)")
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

// MARK: - Methods (private)

extension URLManager {
	private func shouldReturnDefaultPath() -> Bool {
		guard let overridenPath else {
			return true
		}
		return false
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
