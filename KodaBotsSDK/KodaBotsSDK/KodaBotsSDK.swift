//
//  KodaBotsSDK.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 09/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import Foundation
import UIKit
import Lottie

public final class KodaBotsSDK {
    private var isInitialized = false
    internal var clientToken:String?
    public static let shared = KodaBotsSDK()
    private init(){}
    
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
    public func uninitialize() {
        isInitialized = false
    }
    
    internal func gatherPhoneData(userProfile:UserProfile?)-> UserProfile?{
        let webview = UIWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        let userAgentString = webview.stringByEvaluatingJavaScript(from: "navigator.userAgent")
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
    
    public func generateViewController(userProfile:UserProfile?, blockId:String?, backgroundColor:UIColor?, progressColor:UIColor?, customAnimation:Animation?, callbacks:((KodaBotsCallbacks)->Void)?)->KodaBotsWebViewViewController?{
        if isInitialized {
            let viewController = KodaBotsWebViewViewController(nibName: "KodaBotsWebViewViewController", bundle: getPodBundle())
            viewController.backgroundColor = backgroundColor
            viewController.progressColor = progressColor
            viewController.userProfile = userProfile ?? UserProfile()
            viewController.blockId = blockId
            viewController.customAnimation = customAnimation
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
