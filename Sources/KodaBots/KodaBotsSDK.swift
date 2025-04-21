import Foundation
import UIKit
import WebKit
import Lottie

public final class KodaBotsSDK: NSObject {

    // MARK: - Properties (private)

    private var isInitialized = false

    // MARK: - Properties (internal)

    internal var settings: KBSettings?

    public static let shared = KodaBotsSDK()

    private override init() {}

    /**
     * Method used to initialize SDK.
     * Fetches ClientToken and server type from plits file.
     *
     * returns: Boolean value that indicates init state
     */
    public func initialize(debugMessagesEnabled: Bool = false) -> Bool {
        guard let settings = KBSettingsBuilder.buildDefault(debugMessagesEnabled: debugMessagesEnabled) else {
            return false
        }
        self.settings = settings
        isInitialized = true
        return true
    }

    /**
     * Method used to initialize SDK.
     * Fetches ClientToken and server type from settings.
     *
     * returns: Boolean value that indicates init state
     */
    public func initialize(with settings: KBSettings)-> Bool {
        self.settings = settings
        URLManager.shared.type = settings.server
        isInitialized = true
        return true
    }

    /**
     * Method used to uninitialize SDK.
     */
    public func uninitialize() {
        isInitialized = false
    }

    internal func gatherPhoneData(userProfile:UserProfile?)-> UserProfile? {
        // TODO: JL
        let webview = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        let userAgentString = webview.value(forKey: "userAgent") as? String
        let systemVersion = UIDevice.current.systemVersion
        let modelName = UIDevice.modelName
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        printIfNeeded(
            message: "KodaBotsSDK -> UserAgent: \(userAgentString ?? "") ; System Version: \(systemVersion) ; Model Name: \(modelName) ; Language: \(language)",
            priority: .info
        )
        userProfile?.os = "iOS"
        userProfile?.manufacturer = "Apple"
        userProfile?.webviewUserAgent = userAgentString
        userProfile?.model = modelName
        userProfile?.locale = language
        userProfile?.osVersion = systemVersion
        return userProfile
    }

    /**
     * Method used to get unread messages count
     *
     * parameter callback: Callback that returns enum class with result
     */
    public func getUnreadCount(callback:@escaping ((CallResponse)->Void)) {
        if settings?.clientToken != nil && KodaBotsPreferences.shared.getUserId() != nil {
            KodaBotsRestApi.shared.getUnreadCount(onResponse: { response, errorType, errorMessage in
                if response != nil {
                    callback(CallResponse.Response((response?.response?.unread_counter!)!))
                } else {
                    callback(CallResponse.Error(errorMessage ?? ""))
                }
            })
        } else {
            callback(CallResponse.Error("UserID or ClientID are nil"))
        }
    }

    /**
     * If SDK is initialized, will return KodaBotsWebViewViewController that you can display and use.
     *
     * parameter config: Configuration file for SDK. You can set userProfile, conversation blockId and progress/timeout ui customisation
     * parameter callbacks: Callbacks from KodaBots chatbot
     * returns: KodaBotsWebViewController
     */
    public func generateViewController(config:KodaBotsConfig?, callbacks:((KodaBotsCallbacks)->Void)?)->KodaBotsWebViewViewController?{
        if isInitialized {
            let viewController = KodaBotsWebViewViewController(nibName: "KodaBotsWebViewViewController", bundle: Bundle.module)
            viewController.customConfig = config
            if callbacks != nil {
                viewController.callbacks = callbacks!
            }
            return viewController
        } else {
            return nil
        }
    }
}

public enum CallResponse {
    case Response(Int)
    case Error(String)
    case Timeout
}
