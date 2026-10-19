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

	private var customClientID: String?
	private var customURL: String?
	private var serverType: KBServerType?
	private var userId: String? {
		get { UserDefaults.standard.string(forKey: "KodaBotsSample.userId") }
		set { UserDefaults.standard.set(newValue, forKey: "KodaBotsSample.userId") }
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
			let alert = UIAlertController(title: "Set Client ID", message: "", preferredStyle: .alert)
			alert.addTextField { (textField) in
				textField.placeholder = "Client ID"
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
			let alert = UIAlertController(title: "Set Url", message: "", preferredStyle: .alert)
			alert.addTextField { (textField) in
				textField.placeholder = "url"
			}
			alert.addAction(
				UIAlertAction(
					title: "Set",
					style: .default,
					handler: { [weak alert] (_) in
						let url = alert?.textFields?[0].text
						guard let url else { return }
						guard !url.isEmpty else { return }
						self.showToast("url SET: \(url)")
						self.customURL = url
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
		let path = customURL.map {
			KodaURL(base: $0, baseVersion: "", rest: $0, restVersion: "")
		}
		let plist = Bundle.main.object(forInfoDictionaryKey: "KodaBotsSDK") as? [String: Any]
		let plistServer: KBServerType = (plist?["server"] as? String) == "STAGE" ? .stage : .release
		let settings = KBSettings(
			clientToken: customClientID ?? plist?["clientToken"] as? String ?? "",
			server: serverType ?? plistServer,
			debugMessagesEnabled: true,
			path: path,
			webDebugEnabled: true
		)
		return KodaBotsSDK.shared.initialize(with: settings)
	}
}

// MARK: - Constants (private)

private enum K {
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
