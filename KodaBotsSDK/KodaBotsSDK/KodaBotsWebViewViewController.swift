//
//  KodaBotsWebViewViewController.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 09/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import UIKit
import WebKit
import Photos
import JavaScriptCore
import Lottie

public class KodaBotsWebViewViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var loaderWrapper: UIView!
    @IBOutlet weak var loaderIndicator: AnimationView!
    
    var backgroundColor:UIColor?
    var progressColor:UIColor?
    var blockId:String?
    var customAnimation: Animation?
    var userProfile:UserProfile?
    var callbacks:(KodaBotsCallbacks)->Void = {_ in}
    private var isReady = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        setup()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isReady {
            self.webView.callJavascript(data: "KodaBots.onPause();")
        }
        self.webView.delegate = nil
    }
    
    @objc func willEnterForeground() {
        DispatchQueue.main.async {
            if self.isReady {
                self.webView.callJavascript(data: "KodaBots.onResume();")
            }
        }
    }
    
    func setup(){
        if let bgc = backgroundColor {
            loaderWrapper.backgroundColor = bgc
        }
        
        if customAnimation == nil {
            let path = Bundle(for: KodaBotsWebViewViewController.classForCoder()).path(forResource: "default_loader",
                                                                                       ofType: "json") ?? ""
            let animation = Animation.filepath(path)
            loaderIndicator.animation = animation
            if let pc = progressColor {
                loaderIndicator.setValueProvider(ColorValueProvider(pc.lottieColorValue), keypath: AnimationKeypath(keypath: "**.Color"))
            }
        } else {
            loaderIndicator.animation = customAnimation!
        }
        loaderIndicator.contentMode = .scaleToFill
        loaderIndicator.loopMode = .loop
        loaderIndicator.play()
        
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        
        //requestCameraPermission(completion: { granted in
            self.loadURL()
        //})
    }
    
    func loadURL(){
        DispatchQueue.main.async {
            if let url = URL(string:
                "\(Config.shared.BASE_URL!)/mobile/\(Config.shared.API_VERSION!)/?token=\(KodaBotsSDK.shared.clientToken!)"
                ) {
                self.webView.loadRequest(URLRequest(url: url))
                self.webView.delegate = self
            }
        }
    }
    
    func requestCameraPermission(completion: @escaping (_ granted: Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
        case .authorized:
            print("KodaBotsSDK -> Audio Authorization Status - Authorized")
            completion(true)
        case .denied, .restricted:
            print("KodaBotsSDK -> Audio Authorization Status - Denied")
            completion(false)
        case .notDetermined:
            print("KodaBotsSDK -> Audio Authorization Status - Not determined")
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (permissionGranted) in
                if permissionGranted {
                    print("KodaBotsSDK -> Audio Authorization Status - Just authorized")
                    completion(true)
                }
                else {
                    print("KodaBotsSDK -> Audio Authorization Status - Just denied")
                    completion(false)
                }
            })
        }
    }
    
    public func sendBlock(blockId: String)-> Bool{
        if isReady {
            webView.callJavascript(data: "KodaBots.sentBlock(\"\(blockId)\");")
            return true
        } else {
            return false
        }
    }
    
    public func syncUserProfile(profile: UserProfile)->Bool {
        if isReady {
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(KodaBotsSDK.shared.gatherPhoneData(userProfile: profile)!)
                let jsonString = String(data: jsonData, encoding: .utf8)
                webView.callJavascript(data: "KodaBots.syncUserProfile(\(jsonString!));")
                return true
            }
            catch {
                return false
            }
        } else {
            return false
        }
    }
    
    public func simulateError()->Bool {
        if isReady {
            webView.callJavascript(data: "KodaBots.simulateError();")
            return true
        } else {
            return false
        }
    }
    
    internal func initialize(){
        if userProfile != nil && blockId != nil {
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(KodaBotsSDK.shared.gatherPhoneData(userProfile: userProfile)!)
                let jsonString = String(data: jsonData, encoding: .utf8)
                webView.callJavascript(data: "KodaBots.initialize(\(jsonString!),\(blockId!));")
            }
            catch {
                webView.callJavascript(data: "KodaBots.initialize(null,\(blockId!));")
            }
        } else if (userProfile != nil && blockId == nil){
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(KodaBotsSDK.shared.gatherPhoneData(userProfile: userProfile)!)
                let jsonString = String(data: jsonData, encoding: .utf8)
                webView.callJavascript(data: "KodaBots.initialize(\(jsonString!),null);")
            }
            catch {
                webView.callJavascript(data: "KodaBots.initialize(null,null);")
            }
            
        } else if userProfile == nil && blockId != nil {
            webView.callJavascript(data: "KodaBots.initialize(null,\(blockId!));")
        } else {
            webView.callJavascript(data: "KodaBots.initialize(null,null);")
        }
    }
}

extension KodaBotsWebViewViewController: UIWebViewDelegate {
    public func webViewDidStartLoad(_ webView: UIWebView) {
        DispatchQueue.main.async {
            self.loaderWrapper.isHidden = false
            self.loaderIndicator.play()
        }
    }
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        DispatchQueue.main.async {
            let context = self.webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
            let onReadyFunction: @convention(block) (String) -> Void
                = { (msg: String) in
                    KodaBotsPreferences.shared.setUserId(userId: msg)
                    DispatchQueue.main.async {
                        self.loaderIndicator.stop()
                        self.loaderWrapper.isHidden = true
                    }
                    self.isReady = true
            }
            let onStatEventFunction: @convention(block) (String, String) -> Void
                = { (eventType:String, params:String) in
                    self.callbacks(KodaBotsCallbacks.Event(eventType: eventType, params: params))
            }
            let onErrorFunction: @convention(block) (String) -> Void
                = { (error:String) in
                    self.callbacks(KodaBotsCallbacks.Error(error: error))
            }
            let onLinkClickedFunction: @convention(block) (String) -> Void
                = { (url:String) in
                    if let url = URL(string: url) {
                        UIApplication.shared.open(url)
                    }
            }
            if let ios = context.objectForKeyedSubscript("IOS") {
                ios.setObject(unsafeBitCast(onReadyFunction, to: AnyObject.self), forKeyedSubscript: "onReady" as NSCopying & NSObjectProtocol)
                ios.setObject(unsafeBitCast(onStatEventFunction, to: AnyObject.self), forKeyedSubscript: "onStatEvent" as NSCopying & NSObjectProtocol)
                ios.setObject(unsafeBitCast(onErrorFunction, to: AnyObject.self), forKeyedSubscript: "onError" as NSCopying & NSObjectProtocol)
                ios.setObject(unsafeBitCast(onLinkClickedFunction, to: AnyObject.self), forKeyedSubscript: "onLinkClicked" as NSCopying & NSObjectProtocol)
            }
            self.initialize()
        }
    }
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        return true
    }
    
}

public enum KodaBotsCallbacks {
    case Event(eventType:String, params:String)
    case Error(error:String)
}

extension UIWebView {
    func callJavascript(data:String){
        print("KodaBotsSDK -> Calling Javascript: \(data)")
        let requestString = "\(data)"
        let _ = self.stringByEvaluatingJavaScript(from: requestString)
    }
}
