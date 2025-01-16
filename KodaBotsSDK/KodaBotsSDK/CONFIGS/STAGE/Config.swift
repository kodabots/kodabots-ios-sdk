//
//  Config.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 12/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import Foundation

public class Config {

    public static let shared = Config()

    var BASE_URL: String = ""
    var API_VERSION: String = ""
    var REST_BASE_URL: String = ""
    var REST_API_VERSION: String = ""

    private init(){
        let plist = Bundle.main.object(forInfoDictionaryKey: "KodaBotsSDK") as? [String:Any]
        guard let plist else { return }
        if let server = plist["server"] as? String? {
            if server == "STAGE" {
                applyStage()
            } else {
                applyRelease()
            }
        } else {
            applyRelease()
        }
    }

    internal func applyStage(){
        BASE_URL = "https://widget.app2.kodabots.com"
        API_VERSION = "v1"
        REST_BASE_URL = "https://chatbot-bnwtfr6jae-stage.kodabots.com"
        REST_API_VERSION = "v1"
    }

    internal func applyRelease(){
        BASE_URL = "https://web.kodabots.com/mobile"
        API_VERSION = "v1"
        REST_BASE_URL = "https://chatbot-mxwaxhdter.kodabots.com"
        REST_API_VERSION = "v1"
    }
}
