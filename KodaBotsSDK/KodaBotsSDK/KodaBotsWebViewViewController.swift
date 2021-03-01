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
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loaderWrapper: UIView!
    @IBOutlet weak var loaderIndicator: AnimationView!
    @IBOutlet weak var wentWrongWrapper: UIView!
    @IBOutlet weak var wentWrongImage: UIImageView!
    @IBOutlet weak var wentWrongLabel: UILabel!
    @IBOutlet weak var wentWrongButton: UIButton!
    
    private let WENT_WRONG_TIMEOUT = DispatchTimeInterval.seconds(20)
    var customConfig:KodaBotsConfig?
    var callbacks:(KodaBotsCallbacks)->Void = {_ in}
    private var isReady = false
    private var wentWrongTask:DispatchWorkItem?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        wentWrongTask = DispatchWorkItem {
            self.showWentWrong()
        }
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
        self.webView.navigationDelegate = nil
    }
    
    @objc func willEnterForeground() {
        DispatchQueue.main.async {
            if self.isReady {
                self.webView.callJavascript(data: "KodaBots.onResume();")
            }
        }
    }
    
    private func setup(){
        setupProgress()
        setupWentWrong()
        
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        
//        let userContentController = WKUserContentController()
        webView.configuration.userContentController.add(self, name: "onReady")
        webView.configuration.userContentController.add(self, name: "onStatEvent")
        webView.configuration.userContentController.add(self, name: "onError")
        webView.configuration.userContentController.add(self, name: "onLinkClicked")
//        webView.configuration.userContentController = userContentController

        //requestCameraPermission(completion: { granted in
            self.loadURL()
        //})
    }
    
    private func setupProgress(){
        if let bgc = customConfig?.progressConfig?.backgroundColor {
            loaderWrapper.backgroundColor = bgc
        }
        
        if customConfig?.progressConfig?.customAnimation == nil {
            let path = Bundle(for: KodaBotsWebViewViewController.classForCoder()).path(forResource: "default_loader",
                                                                                       ofType: "json") ?? ""
            let animation = Animation.filepath(path)
            loaderIndicator.animation = animation
            if let pc = customConfig?.progressConfig?.progressColor {
                loaderIndicator.setValueProvider(ColorValueProvider(pc.lottieColorValue), keypath: AnimationKeypath(keypath: "**.Color"))
            }
        } else {
            loaderIndicator.animation = customConfig?.progressConfig?.customAnimation!
        }
        loaderIndicator.contentMode = .scaleToFill
        loaderIndicator.loopMode = .loop
        loaderIndicator.play()
    }
    
    private func setupWentWrong(){
        wentWrongLabel.text = "went_wrong_message".localized
        wentWrongButton.setTitle("went_wrong_button".localized, for: .normal)
        wentWrongButton.addTarget(self, action: #selector(wentWrongButtonClicked(_:)), for: .touchUpInside)
        if let background = customConfig?.timeoutConfig?.backgroundColor {
            wentWrongWrapper.backgroundColor = background
        }
        if let customImage = customConfig?.timeoutConfig?.image {
            wentWrongImage.image = customImage
        }
        if let buttonText = customConfig?.timeoutConfig?.buttonText {
            wentWrongButton.setTitle(buttonText, for: .normal)
        }
        if let buttonTextColor = customConfig?.timeoutConfig?.buttonTextColor {
            wentWrongButton.setTitleColor(buttonTextColor, for: .normal)
        }
        if let buttonBackgroundColor = customConfig?.timeoutConfig?.buttonColor {
            wentWrongButton.backgroundColor = buttonBackgroundColor
        }
        if let buttonFont = customConfig?.timeoutConfig?.buttonFont {
            wentWrongButton.titleLabel?.font = buttonFont
        }
        if let buttonFontSize = customConfig?.timeoutConfig?.buttonFontSize {
            let newFont = UIFont(name: (wentWrongButton.titleLabel?.font?.fontName)!, size: CGFloat(buttonFontSize))
            wentWrongButton.titleLabel?.font = newFont
        }
        if let buttonCornerRadius = customConfig?.timeoutConfig?.buttonCornerRadius {
            wentWrongButton.layer.cornerRadius = CGFloat(buttonCornerRadius)
        }
        if let buttonBorderWidth = customConfig?.timeoutConfig?.buttonBorderWidth {
            wentWrongButton.layer.borderWidth = CGFloat(buttonBorderWidth)
        }
        if let buttonBorderColor = customConfig?.timeoutConfig?.buttonBorderColor {
            wentWrongButton.layer.borderColor = buttonBorderColor.cgColor
        }
        if let customMessage = customConfig?.timeoutConfig?.message {
            wentWrongLabel.text = customMessage
        }
        if let customMessageFont = customConfig?.timeoutConfig?.messageFont {
            wentWrongLabel.font = customMessageFont
        }
        if let customMessageFontSize = customConfig?.timeoutConfig?.messageFontSize {
            let newFont = UIFont(name: (wentWrongLabel.font?.fontName)!, size: CGFloat(customMessageFontSize))
            wentWrongLabel.font = newFont
        }
    }
    
    @objc
    func wentWrongButtonClicked(_ sender: Any?){
        wentWrongWrapper.isHidden = true
        loaderWrapper.isHidden = false
        loaderIndicator.play()
        loadURL()
    }
    
    func loadURL(){
        DispatchQueue.main.async {
            if let url = URL(string:
                "\(Config.shared.BASE_URL!)/mobile/\(Config.shared.API_VERSION!)/?token=\(KodaBotsSDK.shared.clientToken!)"
                ) {
                self.webView.load(URLRequest(url: url))

                self.webView.navigationDelegate = self
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
        if customConfig?.userProfile != nil && customConfig?.blockId != nil {
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(KodaBotsSDK.shared.gatherPhoneData(userProfile: customConfig?.userProfile)!)
                let jsonString = String(data: jsonData, encoding: .utf8)
                webView.callJavascript(data: "KodaBots.initialize(\(jsonString!),\(customConfig?.blockId!));")
            }
            catch {
                webView.callJavascript(data: "KodaBots.initialize(null,\(customConfig?.blockId!));")
            }
        } else if (customConfig?.userProfile != nil && customConfig?.blockId == nil){
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(KodaBotsSDK.shared.gatherPhoneData(userProfile: customConfig?.userProfile)!)
                let jsonString = String(data: jsonData, encoding: .utf8)
                webView.callJavascript(data: "KodaBots.initialize(\(jsonString!),null);")
            }
            catch {
                webView.callJavascript(data: "KodaBots.initialize(null,null);")
            }
            
        } else if customConfig?.userProfile == nil && customConfig?.blockId != nil {
            webView.callJavascript(data: "KodaBots.initialize(null,\(customConfig?.blockId!));")
        } else {
            webView.callJavascript(data: "KodaBots.initialize(null,null);")
        }
    }
    
    private func showWentWrong(){
        wentWrongWrapper.isHidden = false
        loaderIndicator.stop()
        loaderWrapper.isHidden = true
    }
}

extension KodaBotsWebViewViewController: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage){
        print("KodaBotsSDK message handler -> received '\(message.name)' with parameters \(message.body)")
        if let body = message.body as? [String : Any?] {
            switch message.name {
            case "onReady":
                if let userId = body["userId"] {
                    self.wentWrongTask?.cancel()
                    KodaBotsPreferences.shared.setUserId(userId: userId as! String)
                    DispatchQueue.main.async {
                        self.loaderIndicator.stop()
                        self.loaderWrapper.isHidden = true
                    }
                    self.isReady = true
                } else {
                    print("KodaBotsSDK message handler -> property 'userId' missing")
                }
                return
            case "onStatEvent":
                if let eventType = body["eventType"], let params = body["params"] {
                    self.callbacks(
                        KodaBotsCallbacks.Event(
                            eventType: (eventType as? String) ?? "",
                            params: (params as? [String:String]) ?? [:]
                        ))
                } else {
                    print("KodaBotsSDK message handler -> property 'eventType' or 'params' missing")
                }
                return
            case "onError":
                if let error = body["error"] {
                    self.callbacks(KodaBotsCallbacks.Error(error: (error as? String) ?? ""))
                } else {
                    print("KodaBotsSDK message handler -> property 'error' missing")
                }
                return
            case "onLinkClicked":
                if let body = message.body as? [String : String],
                   let urlString = body["url"],
                   let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                } else {
                    print("KodaBotsSDK message handler -> property 'url' missing")
                }
                return
            default:
                print("KodaBotsSDK message handler -> unhandled message '\(message.name)'")
            }
        } else{
            print("KodaBotsSDK message handler -> body must be a JSON object, and is: \(message.body)")
        }
    }
    
}


extension KodaBotsWebViewViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        DispatchQueue.main.async {
            self.loaderWrapper.isHidden = false
            self.loaderIndicator.play()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+(customConfig?.timeoutConfig?.timeout ?? WENT_WRONG_TIMEOUT), execute:wentWrongTask!)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            
          
            self.initialize()

            // ------------------- temporary --------------------,
            // ----- remove when we have callbacks working ------
//            DispatchQueue.main.asyncAfter(deadline: .now()+10, execute:{
//                KodaBotsPreferences.shared.setUserId(userId: "1be68070-b686-58f3-aa88-93aa4ef87d3f")
//                DispatchQueue.main.async {
//                    self.loaderIndicator.stop()
//                    self.loaderWrapper.isHidden = true
//                }
//                self.isReady = true
//            })
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.url?.scheme == "tel" {
            UIApplication.shared.openURL(navigationAction.request.url!)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    
}

public enum KodaBotsCallbacks {
    case Event(eventType:String, params:[String:String])
    case Error(error:String)
}

extension WKWebView {
    func callJavascript(data:String){
        print("KodaBotsSDK -> Calling Javascript: \(data)")
        let requestString = "\(data)"
        self.evaluateJavaScript(requestString)
    }
}
extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: "KodaBotsLocalizable", bundle: Bundle(for: KodaBotsWebViewViewController.classForCoder()), value: "", comment: "")
    }
}
