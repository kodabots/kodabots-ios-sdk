import Foundation

public struct KBSettings {
    var clientToken: String
    var server: KBServerType
    var debugMessagesEnabled: Bool

    public init(
        clientToken: String = "",
        server: KBServerType = .release,
        debugMessagesEnabled: Bool = false
    ) {
        self.clientToken = clientToken
        self.server = server
        self.debugMessagesEnabled = debugMessagesEnabled
    }
}
