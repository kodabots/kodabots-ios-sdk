import Foundation

public struct KBSettings {
	var clientToken: String
	var server: KBServerType
	var debugMessagesEnabled: Bool
	var path: KodaURL?

	public init(
		clientToken: String = "",
		server: KBServerType = .release,
		debugMessagesEnabled: Bool = false,
		path: KodaURL? = nil
	) {
		self.clientToken = clientToken
		self.server = server
		self.debugMessagesEnabled = debugMessagesEnabled
		self.path = path
	}
}
