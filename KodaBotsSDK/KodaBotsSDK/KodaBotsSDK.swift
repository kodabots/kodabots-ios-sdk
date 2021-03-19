//
//  KodaBotsSDK.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 09/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import Lottie

public final class KodaBotsSDK {
    private var isInitialized = false
    internal var clientToken:String?
    public static let shared = KodaBotsSDK()
    private init(){}
    
    /**
     * Method used to initialize SDK.
     * Fetches ClientToken from plits file.
     *
     * returns: Boolean value that indicates init state
     */
    public func initialize()-> Bool {
        let plist = Bundle.main.object(forInfoDictionaryKey: "KodaBotsSDK") as! [String:Any]
        if let plistClientToken = plist["clientToken"] {
            clientToken = plistClientToken as! String
            isInitialized = true
            return true
        } else {
            return false
        }
    }
    
    /**
     * Method used to uninitialize SDK.
     */
    public func uninitialize() {
        isInitialized = false
    }
    
    internal func gatherPhoneData(userProfile:UserProfile?)-> UserProfile?{
        let webview = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        let userAgentString = webview.value(forKey: "userAgent") as! String
        var systemVersion = UIDevice.current.systemVersion
        let modelName = UIDevice.modelName
        let language = Bundle.main.preferredLocalizations.first as! NSString
        print("KodaBotsSDK -> UserAgent: \(userAgentString) ; System Version: \(systemVersion) ; Model Name: \(modelName) ; Language: \(language)")
        userProfile?.os = "iOS"
        userProfile?.manufacturer = "Apple"
        userProfile?.webview_user_agent = userAgentString
        userProfile?.model = modelName
        userProfile?.locale = language as String
        userProfile?.os_version = systemVersion
        return userProfile
    }
    
    /**
     * Method used to get unread messages count
     *
     * parameter callback: Callback that returns enum class with result
     */
    public func getUnreadCount(callback:@escaping ((CallResponse)->Void)) {
        if clientToken != nil && KodaBotsPreferences.shared.getUserId() != nil {
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
            let viewController = KodaBotsWebViewViewController(nibName: "KodaBotsWebViewViewController", bundle: getPodBundle())
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

internal func getPodBundle() -> Bundle? {
    let podBundle = Bundle(for: KodaBotsWebViewViewController.classForCoder())
    if let bundleURL = podBundle.url(forResource: "KodaBotsSDK", withExtension: "bundle") {
        return Bundle(url: bundleURL)
    } else {
        return nil
    }
}

public enum CallResponse {
    case Response(Int)
    case Error(String)
    case Timeout
}
