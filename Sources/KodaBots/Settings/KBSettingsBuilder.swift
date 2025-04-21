import Foundation

enum KBSettingsBuilder {
    static func buildDefault(debugMessagesEnabled: Bool = false) -> KBSettings? {
        let plist = Bundle.main.object(forInfoDictionaryKey: K.infoDictionaryKey) as? [String:Any]
        guard
            let plist = plist,
            let plistClientToken = plist[K.clientTokenKey] as? String
        else {
            printIfNeeded(message: "🤖 Failed to load SDK settings from Info.plist")
            return nil
        }
        let serverType = URLManager.shared.type
        return KBSettings(
            clientToken: plistClientToken,
            server: serverType,
            debugMessagesEnabled: debugMessagesEnabled
        )
    }
}

// MARK: - Constants (private)

private enum K {
    static let infoDictionaryKey = "KodaBotsSDK"
    static let clientTokenKey = "clientToken"
}
