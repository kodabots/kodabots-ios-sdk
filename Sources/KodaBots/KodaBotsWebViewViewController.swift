import UIKit
import WebKit
import Photos
import JavaScriptCore
import Lottie
import MediaPlayer
import SnapKit

public class KodaBotsWebViewViewController: UIViewController {

	// MARK: - Subviews (public)

	public let webView = Subviews.makeWebView()

	// MARK: - Subviews (private)

	private let loaderContainerView = Subviews.makeLoaderContainerView()
	private let loaderAnimationView = Subviews.makeLoaderAnimationView()

	private let errorContainerView = Subviews.makeErrorContainerView()
	private let errorStackView = Subviews.makeErrorStackView()
	private let errorImage = Subviews.makeErrorImage()
	private let errorLabel = Subviews.makeErrorLabel()
	private let errorButton = Subviews.makeErrorButton()

	// MARK: - Properties (private)

	private let WENT_WRONG_TIMEOUT = DispatchTimeInterval.seconds(20)
	private var isReady = false
	private var wentWrongTask: DispatchWorkItem?

	// MARK: - Properties

	var customConfig: KodaBotsConfig? {
		didSet {
			guard let layout = customConfig?.layoutConfig else { return }
			DispatchQueue.main.async { [weak self] in guard let self else { return }
				layoutWebView(with: layout)
			}
		}
	}

	var callbacks: (KodaBotsCallbacks) -> Void = {_ in}

	// MARK: - Lifecycle

	public override func viewDidLoad() {
		super.viewDidLoad()
		layout()
		setup()
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
	func errorButtonClicked(_ sender: Any?) {
		errorContainerView.isHidden = true
		loaderContainerView.isHidden = false
		loaderAnimationView.play()
		loadURL()
	}
}

// MARK: - Layout (private)

extension KodaBotsWebViewViewController {
	private func layout() {
		addSubviews()
		layoutWebView()
		layoutLoaderContainerView()
		layoutLoaderAnimationView()
		layoutErrorContainerView()
		layoutErrorStackView()
		layoutErrorImage()
	}

	private func addSubviews() {
		view.addSubview(webView)

		view.addSubview(loaderContainerView)
		loaderContainerView.addSubview(loaderAnimationView)

		view.addSubview(errorContainerView)
		errorContainerView.addSubview(errorStackView)
		errorStackView.addArrangedSubview(errorImage)
		errorStackView.addArrangedSubview(errorLabel)
		errorStackView.addArrangedSubview(errorButton)
	}

	private func layoutWebView() {
		webView.snp.makeConstraints { make in
			make.edges.equalTo(view.safeAreaLayoutGuide)
		}
	}

	private func layoutLoaderContainerView() {
		loaderContainerView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
	}

	private func layoutLoaderAnimationView() {
		loaderAnimationView.snp.makeConstraints { make in
			make.center.equalToSuperview().inset(32)
		}
	}

	private func layoutErrorContainerView() {
		errorContainerView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
	}

	private func layoutErrorStackView() {
		errorStackView.snp.makeConstraints { make in
			make.horizontalEdges.equalToSuperview().inset(16)
			make.centerY.equalToSuperview()
		}
	}

	private func layoutErrorImage() {
		errorImage.snp.makeConstraints { make in
			make.horizontalEdges.equalToSuperview().inset(16)
		}
	}

	private func layoutWebView(with config: KodaBotsLayoutConfig) {
		webView.snp.remakeConstraints { make in
			switch config {
			case .safeArea:
				make.edges.equalTo(view.safeAreaLayoutGuide)
			case .edges:
				make.edges.equalToSuperview()
			case .topEdge:
				make.top.equalToSuperview()
				make.bottom.equalTo(view.safeAreaLayoutGuide)
				make.leading.trailing.bottom.equalToSuperview()
			case .bottomEdge:
				make.top.equalTo(view.safeAreaLayoutGuide)
				make.bottom.equalToSuperview()
				make.leading.trailing.top.equalToSuperview()
			}
		}
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
		errorContainerView.isHidden = true
		wentWrongTask = DispatchWorkItem {
			self.showWentWrong()
		}
	}

	private func setupProgress() {
		let progressConfig = customConfig?.progressConfig
		if let bgc = progressConfig?.backgroundColor {
			loaderContainerView.backgroundColor = bgc
		}
		if progressConfig?.customAnimation == nil {
			do {
				if let url = Bundle.module.url(forResource: "default_loader", withExtension: "json") {
					let data = try Data(contentsOf: url)
					let animation = try LottieAnimation.from(data: data)
					loaderAnimationView.animation = animation
				}
			} catch {
				print("❌ Lottie animation error: \(error)")
			}
			if let pc = progressConfig?.progressColor {
				loaderAnimationView.setValueProvider(ColorValueProvider(pc.lottieColorValue), keypath: AnimationKeypath(keypath: "**.Color"))
			}
		} else {
			loaderAnimationView.animation = customConfig?.progressConfig?.customAnimation!
		}
		loaderAnimationView.contentMode = .scaleToFill
		loaderAnimationView.loopMode = .loop
		loaderAnimationView.play()
	}

	private func setupWentWrong(){
		errorLabel.text = L.wentWrongMessage
		errorButton.setTitle(L.errorButton, for: .normal)
		errorButton.addTarget(self, action: #selector(errorButtonClicked(_:)), for: .touchUpInside)
		if let background = customConfig?.timeoutConfig?.backgroundColor {
			errorContainerView.backgroundColor = background
		}
		if let customImage = customConfig?.timeoutConfig?.image {
			errorImage.image = customImage
		}
		if let buttonText = customConfig?.timeoutConfig?.buttonText {
			errorButton.setTitle(buttonText, for: .normal)
		}
		if let buttonTextColor = customConfig?.timeoutConfig?.buttonTextColor {
			errorButton.setTitleColor(buttonTextColor, for: .normal)
		}
		if let buttonBackgroundColor = customConfig?.timeoutConfig?.buttonColor {
			errorButton.backgroundColor = buttonBackgroundColor
		}
		if let buttonFont = customConfig?.timeoutConfig?.buttonFont {
			errorButton.titleLabel?.font = buttonFont
		}
		if let buttonFontSize = customConfig?.timeoutConfig?.buttonFontSize {
			let newFont = UIFont(name: (errorButton.titleLabel?.font?.fontName)!, size: CGFloat(buttonFontSize))
			errorButton.titleLabel?.font = newFont
		}
		if let buttonCornerRadius = customConfig?.timeoutConfig?.buttonCornerRadius {
			errorButton.layer.cornerRadius = CGFloat(buttonCornerRadius)
		}
		if let buttonBorderWidth = customConfig?.timeoutConfig?.buttonBorderWidth {
			errorButton.layer.borderWidth = CGFloat(buttonBorderWidth)
		}
		if let buttonBorderColor = customConfig?.timeoutConfig?.buttonBorderColor {
			errorButton.layer.borderColor = buttonBorderColor.cgColor
		}
		if let customMessage = customConfig?.timeoutConfig?.message {
			errorLabel.text = customMessage
		}
		if let customMessageFont = customConfig?.timeoutConfig?.messageFont {
			errorLabel.font = customMessageFont
		}
		if let customMessageFontSize = customConfig?.timeoutConfig?.messageFontSize {
			let newFont = UIFont(name: (errorLabel.font?.fontName)!, size: CGFloat(customMessageFontSize))
			errorLabel.font = newFont
		}
		if let customMessageColor = customConfig?.timeoutConfig?.messageTextColor {
			errorLabel.textColor = customMessageColor
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
				let url = URLManager.shared.mobileToken(clientToken: clientToken)
			{
				print("🤖KodaBotsSDK ℹ️ loadURL \(url)")
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
		errorContainerView.isHidden = false
		loaderAnimationView.stop()
		loaderContainerView.isHidden = true
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
						self.loaderAnimationView.stop()
						self.loaderContainerView.isHidden = true
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
			self.loaderContainerView.isHidden = false
			self.loaderAnimationView.play()
		}

		DispatchQueue.main.asyncAfter(deadline: .now()+(customConfig?.timeoutConfig?.timeout ?? WENT_WRONG_TIMEOUT), execute:wentWrongTask!)
	}

	public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		DispatchQueue.main.async {
			self.initialize()
		}
	}

	public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		if navigationAction.request.url?.scheme == "tel" {
			guard let url = navigationAction.request.url else { return }
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
			decisionHandler(.cancel)
		} else if let url = navigationAction.request.url,
							navigationAction.navigationType == .linkActivated {
			UIApplication.shared.open(url)
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

// MARK: - Subviews (private)

@MainActor
private enum Subviews {
	static func makeWebView() -> WKWebView {
		let view = WKWebView()
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}

	static func makeLoaderContainerView() -> UIView {
		let view = UIView()
		view.backgroundColor = .white
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}

	static func makeLoaderAnimationView() -> LottieAnimationView {
		let view = LottieAnimationView()
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}

	static func makeErrorContainerView() -> UIView {
		let view = UIView()
		view.backgroundColor = .white
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}

	static func makeErrorStackView() -> UIStackView {
		let stackView = UIStackView()
		stackView.axis = .vertical
		stackView.alignment = .center
		stackView.distribution = .equalSpacing
		stackView.spacing = 16
		stackView.translatesAutoresizingMaskIntoConstraints = false
		return stackView
	}

	static func makeErrorImage() -> UIImageView {
		let image = UIImageView()
		image.image = UIImage(named: "went_wrong", in: .module, with: nil)
		image.contentMode = .scaleAspectFit
		image.translatesAutoresizingMaskIntoConstraints = false
		return image
	}

	static func makeErrorLabel() -> UILabel {
		let label = UILabel()
		label.textColor = .systemPink
		label.font = .systemFont(ofSize: 24)
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}

	static func makeErrorButton() -> UIButton {
		let button = UIButton(type: .system)
		button.backgroundColor = .systemPink
		button.setTitleColor(.white, for: .normal)
		button.layer.cornerRadius = 14
		button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
		button.titleLabel?.font = .boldSystemFont(ofSize: 16)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
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
	static let errorButton = "went_wrong_button".localized()
}

