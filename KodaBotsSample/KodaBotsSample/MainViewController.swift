//
//  MainViewController.swift
//  KodaBotsSample
//
//  Created by Felislynx.Silae on 12/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import UIKit
import KodaBotsSDK

class MainViewController: UIViewController {

    // MARK: - Properties (private)

    private var customClientID: String?

    // MARK: - Properties

    var kodaBotsWebView:KodaBotsWebViewViewController?
    var callbacks:(KodaBotsCallbacks)->Void = { callback in
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
    @IBOutlet weak var test: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        controllsButton.addTarget(self, action: #selector(onControllsClicked(_:)), for: .touchUpInside)
    }
    
    @objc
    func onControllsClicked(_ sender:Any?){
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
                        URLManager.shared.type = .release
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
                        URLManager.shared.type = .stage
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
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                if self.kodaBotsWebView != nil {
                    let profile = UserProfile()
                    profile.first_name = alert?.textFields![0].text
                    profile.last_name = alert?.textFields![1].text
                    profile.custom_parameters["custom_key"] =  alert?.textFields![2].text
                    if self.kodaBotsWebView!.syncUserProfile(profile: profile) == false{
                        self.showToast("INITIALIZE WEBVIEW")
                    }
                } else {
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
        let closeAction = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default) { (action) in
            optionMenu.dismiss(animated: true, completion: nil)
        }
        optionMenu.addAction(initializeAction)
        optionMenu.addAction(setClientIDAction)
        optionMenu.addAction(getUnreadCountAction)
        optionMenu.addAction(syncProfileAction)
        optionMenu.addAction(sendBlockAction)
        optionMenu.addAction(simulateAlertAction)
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
    
    func initializeWebview(){
        DispatchQueue.main.async {
            guard self.initializeKodaBot() else { return }
            let config = KodaBotsConfig()
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
        if let customClientID {
            guard KodaBotsSDK.shared.initialize(clientToken: customClientID) else {
                print("KodaBotsSDK - NOT INITILIZED")
                return false
            }
        } else {
            guard KodaBotsSDK.shared.initialize() else {
                print("KodaBotsSDK - NOT INITILIZED")
                return false
            }
        }
        print("KodaBotsSDK - INITILIZED")
        return true
    }
}
