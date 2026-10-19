import Foundation

public struct KBSettings {
	var clientToken: String
	var server: KBServerType
	var debugMessagesEnabled: Bool
	var path: KodaURL?
	var webDebugEnabled: Bool

	/**
	 * - Parameters:
	 *   - webDebugEnabled: Debug only. Logs webview console, JS errors, storage access and JS ↔ native messages,
	 *     and makes the webview inspectable in Safari Web Inspector (iOS 16.4+). Do not enable in production builds.
	 */
	public init(
		clientToken: String = "",
		server: KBServerType = .release,
		debugMessagesEnabled: Bool = false,
		path: KodaURL? = nil,
		webDebugEnabled: Bool = false
	) {
		self.clientToken = clientToken
		self.server = server
		self.debugMessagesEnabled = debugMessagesEnabled
		self.path = path
		self.webDebugEnabled = webDebugEnabled
	}
}
