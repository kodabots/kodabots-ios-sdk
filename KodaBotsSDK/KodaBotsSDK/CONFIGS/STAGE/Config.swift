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
        BASE_URL = "https://web.staging.koda.ai"
        API_VERSION = "v1"
        REST_BASE_URL = "https://bot.staging.koda.ai"
        REST_API_VERSION = "v1"
    }

    internal func applyRelease(){
        BASE_URL = "https://web.eu-pl.koda.ai"
        API_VERSION = "v1"
        REST_BASE_URL = "https://bot.eu-pl.koda.ai"
        REST_API_VERSION = "v1"
    }
}
