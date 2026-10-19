//
//  MainViewController.swift
//  KodaBotsSample
//
//  Created by Felislynx.Silae on 12/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import UIKit
import KodaBots

final class MainViewController: UIViewController {

	// MARK: - Properties (private)

	// Test settings entered from CONTROLLS are kept between launches.
	private var customClientID: String? {
		get { UserDefaults.standard.string(forKey: K.Keys.clientID) }
		set { UserDefaults.standard.set(newValue, forKey: K.Keys.clientID) }
	}
	private var serverType: KBServerType? {
		get {
			switch UserDefaults.standard.string(forKey: K.Keys.server) {
			case "STAGE": return .stage
			case "RELEASE": return .release
			default: return nil
			}
		}
		set {
			let value: String? = switch newValue {
			case .stage: "STAGE"
			case .release: "RELEASE"
			case nil: nil
			}
			UserDefaults.standard.set(value, forKey: K.Keys.server)
		}
	}
	private var customPath: (base: String, rest: String, version: String)? {
		get {
			guard
				let base = UserDefaults.standard.string(forKey: K.Keys.baseURL),
				let rest = UserDefaults.standard.string(forKey: K.Keys.restURL),
				let version = UserDefaults.standard.string(forKey: K.Keys.version)
			else { return nil }
			return (base, rest, version)
		}
		set {
			UserDefaults.standard.set(newValue?.base, forKey: K.Keys.baseURL)
			UserDefaults.standard.set(newValue?.rest, forKey: K.Keys.restURL)
			UserDefaults.standard.set(newValue?.version, forKey: K.Keys.version)
		}
	}
	private var userId: String? {
		get { UserDefaults.standard.string(forKey: K.Keys.userID) }
		set { UserDefaults.standard.set(newValue, forKey: K.Keys.userID) }
	}
	private var plistSettings: (clientID: String?, server: KBServerType) {
		let plist = Bundle.main.object(forInfoDictionaryKey: "KodaBotsSDK") as? [String: Any]
		let clientID = plist?["clientToken"] as? String
		let server: KBServerType = (plist?["server"] as? String) == "STAGE" ? .stage : .release
		return (clientID == K.plistPlaceholder ? nil : clientID, server)
	}

	// MARK: - Properties

	var kodaBotsWebView: KodaBotsWebViewViewController?
	var callbacks: (KodaBotsCallbacks) -> Void = { callback in
		switch callback {
		case .Event(let type, let parameters):
			print("KodaBotsSDK -> Event received: \(type) - \(parameters)")
		case .Error(let error):
			print("KodaBotsSDK -> Error received: \(error)")
		}
	}

	// MARK: - IBOUtlet

	@IBOutlet weak var controllsButton: UIButton!
	@IBOutlet weak var webViewContainer: UIView!

	override func viewDidLoad() {
		super.viewDidLoad()
		controllsButton.addTarget(self, action: #selector(onControllsClicked(_:)), for: .touchUpInside)
	}

	@objc
	func onControllsClicked(_ sender:Any?) {
		let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let initializeAction = UIAlertAction(title: NSLocalizedString("INITIALIZE WEBVIEW", comment: ""), style: .default){ (action) in
			self.initializeWebview()
		}
		let setClientIDAction = UIAlertAction(title: NSLocalizedString("SET CLIENT ID", comment: ""), style: .default) { (action) in
			let alert = UIAlertController(title: "Set Client ID", message: "Choose the server the token belongs to", preferredStyle: .alert)
			alert.addTextField { (textField) in
				textField.placeholder = "Client ID"
				textField.text = self.customClientID
				textField.autocapitalizationType = .none
				textField.autocorrectionType = .no
			}
			alert.addAction(
				UIAlertAction(
					title: "Set (release)",
					style: .default,
					handler: { [weak alert] (_) in
						let clientID = alert?.textFields?[0].text
						guard let clientID else { return }
						guard !clientID.isEmpty else { return }
						self.showToast("CLIENT ID SET: \(clientID)")
						self.customClientID = clientID
						self.serverType = .release
					}
				)
			)
			alert.addAction(
				UIAlertAction(
					title: "Set (stage)",
					style: .default,
					handler: { [weak alert] (_) in
						let clientID = alert?.textFields?[0].text
						guard let clientID else { return }
						guard !clientID.isEmpty else { return }
						self.showToast("CLIENT ID SET: \(clientID)")
						self.customClientID = clientID
						self.serverType = .stage
					}
				)
			)
			alert.addAction(
				UIAlertAction(
					title: "Cancel",
					style: .default,
					handler: { _ in
						optionMenu.dismiss(animated: true, completion: nil)
					}
				)
			)
			self.present(alert, animated: true, completion: nil)
		}
		let setURL = UIAlertAction(title: NSLocalizedString("SET URL", comment: ""), style: .default) { (action) in
			let alert = UIAlertController(
				title: "Set URL",
				message: "Overrides the server chosen in SET CLIENT ID.\nChat host, e.g. https://web.staging.koda.ai\nREST host, e.g. https://bot.staging.koda.ai",
				preferredStyle: .alert
			)
			let current = self.customPath
			alert.addTextField { (textField) in
				textField.placeholder = "Chat host (https://...)"
				textField.text = current?.base
				textField.keyboardType = .URL
				textField.autocapitalizationType = .none
				textField.autocorrectionType = .no
			}
			alert.addTextField { (textField) in
				textField.placeholder = "REST host (https://...)"
				textField.text = current?.rest
				textField.keyboardType = .URL
				textField.autocapitalizationType = .none
				textField.autocorrectionType = .no
			}
			alert.addTextField { (textField) in
				textField.placeholder = "Version"
				textField.text = current?.version ?? "v1"
				textField.autocapitalizationType = .none
				textField.autocorrectionType = .no
			}
			alert.addAction(
				UIAlertAction(
					title: "Set",
					style: .default,
					handler: { [weak alert] (_) in
						let fields = (alert?.textFields ?? []).map { self.trimmedHost($0.text) }
						guard fields.count == 3, !fields[0].isEmpty else {
							self.showToast("CHAT HOST IS REQUIRED")
							return
						}
						let base = fields[0]
						let rest = fields[1].isEmpty ? base : fields[1]
						guard base.hasPrefix("https://"), rest.hasPrefix("https://") else {
							self.showToast("USE https:// (iOS blocks http)")
							return
						}
						self.customPath = (base, rest, fields[2])
						self.showToast("URL SET: \(self.chatURLDescription())")
					}
				)
			)
			alert.addAction(
				UIAlertAction(
					title: "Clear (use server)",
					style: .destructive,
					handler: { _ in
						self.customPath = nil
						self.showToast("URL CLEARED")
					}
				)
			)
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
			self.present(alert, animated: true, completion: nil)
		}
		let showConfigAction = UIAlertAction(title: NSLocalizedString("SHOW CONFIG", comment: ""), style: .default) { (action) in
			let alert = UIAlertController(title: "Config", message: self.configDescription(), preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default))
			alert.addAction(
				UIAlertAction(
					title: "Reset all",
					style: .destructive,
					handler: { _ in
						self.customClientID = nil
						self.serverType = nil
						self.customPath = nil
						self.userId = nil
						self.showToast("CONFIG RESET")
					}
				)
			)
			self.present(alert, animated: true)
		}
		let setUserIdAction = UIAlertAction(title: NSLocalizedString("SET USER ID", comment: ""), style: .default) { (action) in
			let alert = UIAlertController(title: "Set User ID", message: "Used as UserProfile.id on next INITIALIZE WEBVIEW (max 36 chars, empty = none)", preferredStyle: .alert)
			alert.addTextField { (textField) in
				textField.placeholder = "User ID"
				textField.text = self.userId
			}
			alert.addAction(
				UIAlertAction(
					title: "Set",
					style: .default,
					handler: { [weak alert] (_) in
						let userId = alert?.textFields?[0].text ?? ""
						self.userId = userId.isEmpty ? nil : userId
						self.showToast("USER ID SET: \(self.userId ?? "none")")
					}
				)
			)
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
			self.present(alert, animated: true, completion: nil)
		}
		let getUnreadCountAction = UIAlertAction(title: NSLocalizedString("GET UNREAD COUNT", comment: ""), style: .default){ (action) in
			KodaBotsSDK.shared.getUnreadCount(callback: { response in
				switch(response){
				case .Response(let data):
					self.showToast("Unread messages: \(data)")
				case .Error(let error):
					print("KodaBotsSample -> Error \(error)")
					self.showToast("Error \(error)")
				case .Timeout:
					print("KodaBotsSample -> Timeout")
					self.showToast("TIMEOUT")
				}
			})
		}
		let syncProfileAction = UIAlertAction(title: NSLocalizedString("SYNC PROFILE", comment: ""), style: .default){ (action) in
			let alert = UIAlertController(title: "Sync profile", message: "", preferredStyle: .alert)
			alert.addTextField { (textField) in
				textField.text = "First Name"
			}
			alert.addTextField { (textField) in
				textField.text = "Last Name"
			}
			alert.addTextField { (textField) in
				textField.text = "Custom key"
			}
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert, weak self] (_) in
				guard let self else { return }
				guard let kodaBotsWebView else {
					self.showToast("kodaBotsWebView is nil")
					return
				}
				let profile = UserProfile()
				profile.firstName = alert?.textFields![0].text
				profile.lastName = alert?.textFields![1].text
				profile.customParameters["custom_key"] =  alert?.textFields![2].text
				if self.kodaBotsWebView!.syncUserProfile(profile: profile) == false{
					self.showToast("INITIALIZE WEBVIEW")
				}
			}))
			self.present(alert, animated: true, completion: nil)
		}
		let sendBlockAction = UIAlertAction(title: NSLocalizedString("SET BLOCK ID", comment: ""), style: .default) { (action) in
			let alert = UIAlertController(title: "Set blockId", message: "", preferredStyle: .alert)
			alert.addTextField { (textField) in
				textField.placeholder = "Block ID"
			}
			alert.addTextField { (textField) in
				textField.placeholder = "Param Key (Optional)"
			}
			alert.addTextField { (textField) in
				textField.placeholder = "Param Value (Optional)"
			}
			alert.addAction(
				UIAlertAction(
					title: "OK",
					style: .default,
					handler: { [weak alert] (_) in
						if self.kodaBotsWebView != nil {
							let blockID = alert?.textFields?[0].text ?? ""
							let paramKey = alert?.textFields?[1].text
							let paramValue = alert?.textFields?[2].text
							var params: [String:String]? = nil
							if
								let paramKey, !paramKey.isEmpty,
								let paramValue, !paramValue.isEmpty
							{
								params = [paramKey:paramValue]
							}
							if !self.kodaBotsWebView!.sendBlock(blockId: blockID, params: params) {
								self.showToast("INITIALIZE WEBVIEW")
							}
						} else {
							self.showToast("INITIALIZE WEBVIEW")
						}
					}
				)
			)
			self.present(alert, animated: true, completion: nil)
		}
		let simulateAlertAction = UIAlertAction(title: NSLocalizedString("SIMULATE ERROR", comment: ""), style: .default){ (action) in
			if self.kodaBotsWebView != nil {
				if self.kodaBotsWebView!.simulateError() == false{
					self.showToast("INITIALIZE WEBVIEW")
				}
			} else {
				self.showToast("INITIALIZE WEBVIEW")
			}
		}
		let clearCacheAction = UIAlertAction(title: NSLocalizedString("CLEAR CACHE", comment: ""), style: .default){ (action) in
			KodaBotsSDK.shared.clearCache()
			self.showToast("CACHE CLEARED")
		}
		let closeWebviewAction = UIAlertAction(title: NSLocalizedString("CLOSE WEBVIEW", comment: ""), style: .default){ (action) in
			self.closeWebview()
		}
		let showCacheAction = UIAlertAction(title: NSLocalizedString("SHOW CACHE", comment: ""), style: .default){ (action) in
			// Debug only: reads SDK storage directly to show what the webview saved.
			let cache = UserDefaults.standard.dictionary(forKey: "KEY_WEB_CACHE") as? [String: String] ?? [:]
			print("KodaBotsSample -> Cache: \(cache)")
			let message = cache.isEmpty
				? "Cache is empty"
				: cache.map { "\($0.key): \($0.value.prefix(200))" }.sorted().joined(separator: "\n\n")
			let alert = UIAlertController(title: "Cache (\(cache.count))", message: message, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default))
			self.present(alert, animated: true)
		}
		let testCacheBridgeAction = UIAlertAction(title: NSLocalizedString("TEST CACHE BRIDGE", comment: ""), style: .default){ (action) in
			guard let kodaBotsWebView = self.kodaBotsWebView else {
				self.showToast("INITIALIZE WEBVIEW")
				return
			}
			kodaBotsWebView.evaluateDebugJavaScript(K.cacheBridgeTestScript) { result in
				print("KodaBotsSample -> Cache bridge test: \(result)")
				let alert = UIAlertController(title: "Cache bridge test", message: result, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .default))
				self.present(alert, animated: true)
			}
		}
		let closeAction = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default) { (action) in
			optionMenu.dismiss(animated: true, completion: nil)
		}
		optionMenu.addAction(initializeAction)
		optionMenu.addAction(showConfigAction)
		optionMenu.addAction(setClientIDAction)
		optionMenu.addAction(setURL)
		optionMenu.addAction(setUserIdAction)
		optionMenu.addAction(getUnreadCountAction)
		optionMenu.addAction(syncProfileAction)
		optionMenu.addAction(sendBlockAction)
		optionMenu.addAction(simulateAlertAction)
		optionMenu.addAction(closeWebviewAction)
		optionMenu.addAction(showCacheAction)
		optionMenu.addAction(testCacheBridgeAction)
		optionMenu.addAction(clearCacheAction)
		optionMenu.addAction(closeAction)
		present(optionMenu, animated: true, completion: nil)
	}

	func showToast(_ message:String){
		DispatchQueue.main.async {
			let alert = UIAlertController(title: message, message: "", preferredStyle: UIAlertController.Style.alert)
			self.present(alert, animated: true, completion: nil)
			DispatchQueue.main.asyncAfter(deadline: .now() + 2.75) {
				alert.dismiss(animated: true, completion: nil)
			}
		}
	}

	func closeWebview() {
		guard let viewController = kodaBotsWebView else {
			showToast("WEBVIEW NOT INITIALIZED")
			return
		}
		viewController.willMove(toParent: nil)
		viewController.view.removeFromSuperview()
		viewController.removeFromParent()
		kodaBotsWebView = nil
	}

	func initializeWebview(){
		DispatchQueue.main.async {
			if self.kodaBotsWebView != nil {
				self.closeWebview()
			}
			guard self.initializeKodaBot() else { return }
			let config = KodaBotsConfig()
			config.userProfile.id = self.userId
			config.progressConfig = KodaBotsProgressConfig()
			config.progressConfig?.backgroundColor = UIColor.white
			config.progressConfig?.progressColor = UIColor.red
			if let viewController = KodaBotsSDK.shared.generateViewController(config:config, callbacks: self.callbacks) {
				self.kodaBotsWebView = viewController
				self.webViewContainer.addSubview(viewController.view)
				self.addChild(viewController)
				viewController.didMove(toParent: self)
				viewController.view.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([
					viewController.view.bottomAnchor.constraint(equalTo: self.webViewContainer.bottomAnchor),
					viewController.view.topAnchor.constraint(equalTo: self.webViewContainer.topAnchor),
					viewController.view.leadingAnchor.constraint(equalTo: self.webViewContainer.leadingAnchor),
					viewController.view.trailingAnchor.constraint(equalTo: self.webViewContainer.trailingAnchor)
				])
			}
		}
	}

	func initializeKodaBot() -> Bool {
		guard let clientID = customClientID ?? plistSettings.clientID else {
			showToast("SET CLIENT ID FIRST")
			return false
		}
		let path = customPath.map {
			KodaURL(base: $0.base, baseVersion: $0.version, rest: $0.rest, restVersion: $0.version)
		}
		let settings = KBSettings(
			clientToken: clientID,
			server: serverType ?? plistSettings.server,
			debugMessagesEnabled: true,
			path: path,
			webDebugEnabled: true
		)
		return KodaBotsSDK.shared.initialize(with: settings)
	}

	private func trimmedHost(_ text: String?) -> String {
		var host = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
		while host.hasSuffix("/") { host.removeLast() }
		return host
	}

	/// Mirrors how the SDK builds the chat URL (URLManager.mobileToken) so testers can see where the app connects.
	private func chatURLDescription() -> String {
		let token = customClientID ?? plistSettings.clientID ?? "<no token>"
		if let customPath {
			return customPath.version.isEmpty
				? "\(customPath.base)/mobile/?token=\(token)"
				: "\(customPath.base)/mobile/\(customPath.version)?token=\(token)"
		}
		let base = (serverType ?? plistSettings.server) == .stage ? "https://web.staging.koda.ai" : "https://web.eu-pl.koda.ai"
		return "\(base)/mobile/v1?token=\(token)"
	}

	private func configDescription() -> String {
		let server = serverType ?? plistSettings.server
		return [
			"Client ID: \(customClientID ?? plistSettings.clientID ?? "not set")",
			"Server: \(server == .stage ? "stage" : "release")\(customPath != nil ? " (overridden by URL)" : "")",
			"Chat host: \(customPath?.base ?? "default")",
			"REST host: \(customPath?.rest ?? "default")",
			"User ID: \(userId ?? "not set")",
			"",
			"Chat URL:",
			chatURLDescription()
		].joined(separator: "\n")
	}
}

// MARK: - Constants (private)

private enum K {
	static let plistPlaceholder = "INSERT_YOUR_TOKEN_HERE"

	enum Keys {
		static let clientID = "KodaBotsSample.clientID"
		static let server = "KodaBotsSample.server"
		static let baseURL = "KodaBotsSample.baseURL"
		static let restURL = "KodaBotsSample.restURL"
		static let version = "KodaBotsSample.version"
		static let userID = "KodaBotsSample.userId"
	}

	/// Round trip through readCache / saveCache, the same calls the chatbot webview makes.
	static let cacheBridgeTestScript = """
	const handlers = window.webkit.messageHandlers;
	const key = "kb_debug_test";
	const value = JSON.stringify({ ts: Date.now() });
	const saved = await handlers.saveCache.postMessage({ key, value });
	const read = await handlers.readCache.postMessage({ key });
	await handlers.saveCache.postMessage({ key, value: null });
	const afterDelete = await handlers.readCache.postMessage({ key });
	let invalidValue;
	try { await handlers.saveCache.postMessage({ key, value: 123 }); invalidValue = "accepted"; }
	catch (error) { invalidValue = "rejected: " + error.message; }
	const ok = saved === true && read === value && afterDelete === null && invalidValue.startsWith("rejected");
	return JSON.stringify({ ok, read, afterDelete, invalidValue });
	"""
}
