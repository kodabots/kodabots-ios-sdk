import UIKit
import WebKit
import Photos
import JavaScriptCore
import Lottie

import MediaPlayer

public class KodaBotsWebViewViewController: UIViewController {

    // MARK: - Properties IBOutlet

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loaderWrapper: UIView!
    @IBOutlet weak var loaderIndicator: LottieAnimationView!
    @IBOutlet weak var wentWrongWrapper: UIView!
    @IBOutlet weak var wentWrongImage: UIImageView!
    @IBOutlet weak var wentWrongLabel: UILabel!
    @IBOutlet weak var wentWrongButton: UIButton!

    // MARK: - Properties (private)

    private let WENT_WRONG_TIMEOUT = DispatchTimeInterval.seconds(20)
    private var isReady = false
    private var wentWrongTask: DispatchWorkItem?

    // MARK: - Properties

    var customConfig: KodaBotsConfig?
    var callbacks: (KodaBotsCallbacks) -> Void = {_ in}

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
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

    @objc
    func willEnterForeground() {
        DispatchQueue.main.async {
            if self.isReady {
                self.webView.callJavascript(data: "KodaBots.onResume();")
            }
        }
    }

    @objc
    func handleAppDidEnterBackground() {
        guard isReady else { return }
        webView.callJavascript(data: "KodaBots.onPause();")
    }

    @objc
    func wentWrongButtonClicked(_ sender: Any?){
        wentWrongWrapper.isHidden = true
        loaderWrapper.isHidden = false
        loaderIndicator.play()
        loadURL()
    }
}

// MARK: - Methods (private)

extension KodaBotsWebViewViewController {
    private func setup() {
        setupObservers()
        setupWentWrongTask()
        setupProgress()
        setupWentWrong()
        setupWebData()
        setupWebView()
        loadURL()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    private func setupWentWrongTask() {
        wentWrongTask = DispatchWorkItem {
            self.showWentWrong()
        }
    }

    private func setupProgress() {
        let progressConfig = customConfig?.progressConfig
        if let bgc = progressConfig?.backgroundColor {
            loaderWrapper.backgroundColor = bgc
        }
        if progressConfig?.customAnimation == nil {
            do {
                if let url = Bundle.module.url(forResource: "default_loader", withExtension: "json") {
                    let data = try Data(contentsOf: url)
                    let animation = try LottieAnimation.from(data: data)
                    loaderIndicator.animation = animation
                }
            } catch {
                print("❌ Lottie animation error: \(error)")
            }
            if let pc = progressConfig?.progressColor {
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
        wentWrongLabel.text = L.wentWrongMessage
        wentWrongButton.setTitle(L.wentWrongButton, for: .normal)
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
        if let customMessageColor = customConfig?.timeoutConfig?.messageTextColor {
            wentWrongLabel.textColor = customMessageColor
        }
    }

    private func setupWebData() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]) as? Set<String>
        guard let websiteDataTypes = websiteDataTypes else { return }
        let date = Date(timeIntervalSince1970: 0)

        WKWebsiteDataStore.default()
            .removeData(
                ofTypes: websiteDataTypes,
                modifiedSince: date,
                completionHandler: { }
            )
    }

    private func setupWebView() {
        webView.configuration.userContentController.add(self, name: "onReady")
        webView.configuration.userContentController.add(self, name: "onStatEvent")
        webView.configuration.userContentController.add(self, name: "onError")
        webView.configuration.userContentController.add(self, name: "onLinkClicked")
    }
}

// MARK: - Methods (private)

extension KodaBotsWebViewViewController {
    func loadURL() {
        DispatchQueue.main.async {
            if
                let clientToken = KodaBotsSDK.shared.settings?.clientToken,
                let url = URL(string: "\(URLManager.shared.base)/mobile/\(URLManager.shared.baseVersion)?token=\(clientToken)")
            {
                self.webView.load(URLRequest(url: url))
                self.webView.navigationDelegate = self
            }
        }
    }

    func requestCameraPermission(completion: @escaping (_ granted: Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
        case .authorized:
            printIfNeeded(message: "Audio Authorization Status - Authorized", priority: .info)
            completion(true)
        case .denied, .restricted:
            printIfNeeded(message: "Audio Authorization Status - Denied", priority: .warning)
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (permissionGranted) in
                if permissionGranted {
                    printIfNeeded(message: "Audio Authorization Status - Just authorized", priority: .info)
                    completion(true)
                }
                else {
                    printIfNeeded(message: "Audio Authorization Status - Just denied", priority: .warning)
                    completion(false)
                }
            })
        @unknown default:
            printIfNeeded(message: "Audio Authorization Status - @unknown default", priority: .warning)
        }
    }

    /**
     * Sends the conversation block ID along with optional custom parameters.
     *
     * - Parameters:
     *   - blockId: The ID of the conversation block.
     *   - params: Optional custom parameters to include in the request.
     * - Returns: `true` if the method was successfully invoked.
     */
    public func sendBlock(blockId: String, params: [String:String]? = nil) -> Bool {
        guard isReady else { return false }
        guard let params, !params.isEmpty else {
            webView.callJavascript(data: "KodaBots.sentBlock(\"\(blockId)\");")
            return true
        }
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []),
            let encodedParams = String(data: jsonData, encoding: .utf8)
        else {
            return false
        }
        webView.callJavascript(data: "KodaBots.sentBlock(\"\(blockId)\",\(encodedParams));")
        return true
    }

    /**
     * Method used to set new user profile
     *
     * parameter userProfile: new user profile
     * returns: true if invoked
     */
    public func syncUserProfile(profile: UserProfile)->Bool {
        if isReady {
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(KodaBotsSDK.shared.gatherPhoneData(userProfile: profile)!)
                let jsonString = String(data: jsonData, encoding: .utf8)
                webView.callJavascript(data: "KodaBots.syncUserProfile(\(jsonString ?? ""));")
                return true
            }
            catch {
                return false
            }
        } else {
            return false
        }
    }

    /**
     * Method used to simulate error
     *
     * returns: true if invoked
     */
    public func simulateError()->Bool {
        if isReady {
            webView.callJavascript(data: "KodaBots.simulateError();")
            return true
        } else {
            return false
        }
    }

    internal func initialize() {
        if customConfig?.userProfile != nil && customConfig?.blockId != nil {
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(KodaBotsSDK.shared.gatherPhoneData(userProfile: customConfig?.userProfile)!)
                let jsonString = String(data: jsonData, encoding: .utf8)
                webView.callJavascript(data: "KodaBots.initialize(\(jsonString ?? ""),\(customConfig?.blockId ?? ""));")
            }
            catch {
                webView.callJavascript(data: "KodaBots.initialize(null,\(customConfig?.blockId ?? ""));")
            }
        } else if (customConfig?.userProfile != nil && customConfig?.blockId == nil){
            do {
                let jsonEncoder = JSONEncoder()
                guard let userProfile = KodaBotsSDK.shared.gatherPhoneData(userProfile: customConfig?.userProfile) else { return }
                let jsonData = try jsonEncoder.encode(userProfile)
                let jsonString = String(data: jsonData, encoding: .utf8)
                webView.callJavascript(data: "KodaBots.initialize(\(jsonString ?? ""),null);")
            }
            catch {
                webView.callJavascript(data: "KodaBots.initialize(null,null);")
            }

        } else if customConfig?.userProfile == nil && customConfig?.blockId != nil {
            webView.callJavascript(data: "KodaBots.initialize(null,\(customConfig?.blockId ?? ""));")
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

// MARK: - WKScriptMessageHandler

extension KodaBotsWebViewViewController: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        printIfNeeded(message: "received '\(message.name)' with parameters \(message.body)", priority: .info)
        if let body = message.body as? [String : Any?] {
            switch message.name {
            case "onReady":
                if let userId = body["userId"] as? String {
                    self.wentWrongTask?.cancel()
                    KodaBotsPreferences.shared.setUserId(userId: userId)
                    DispatchQueue.main.async {
                        self.loaderIndicator.stop()
                        self.loaderWrapper.isHidden = true
                    }
                    self.isReady = true
                } else {
                    printIfNeeded(message: "property 'userId' missing", priority: .warning)
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
                    printIfNeeded(message: "property 'eventType' or 'params' missing", priority: .warning)
                }
                return
            case "onError":
                if let error = body["error"] {
                    self.callbacks(KodaBotsCallbacks.Error(error: (error as? String) ?? ""))
                } else {
                    printIfNeeded(message: "property 'error' missing", priority: .warning)
                }
                return
            case "onLinkClicked":
                if let body = message.body as? [String : String],
                   let urlString = body["url"],
                   let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                } else {
                    printIfNeeded(message: "property 'url' missing", priority: .warning)
                }
                return
            default:
                printIfNeeded(message: "unhandled message '\(message.name)'", priority: .warning)
            }
        } else {
            printIfNeeded(message: "body must be a JSON object, and is: \(message.body)", priority: .warning)
        }
    }
}

// MARK: - WKNavigationDelegate

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
            guard let url = navigationAction.request.url else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
        printIfNeeded(message: "Calling Javascript: \(data)", priority: .info)
        let requestString = "\(data)"
        self.evaluateJavaScript(requestString)
    }
}

// MARK: - Constants (private)

private enum K {
    enum Lottie {
        static let loader = "default_loader"
        static let file = "json"
    }
}

// MARK: - Localized (private)

private enum L {
    static let wentWrongMessage = "went_wrong_message".localized()
    static let wentWrongButton = "went_wrong_button".localized()
}
