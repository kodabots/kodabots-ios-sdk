//
//  Model.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 09/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import Foundation

public class UserProfile:NSObject, Codable {
    public var first_name:String?
    public var last_name:String?
    public var email:String?
    public var custom_key:String?
    public var os: String?
    public var os_version: String?
    public var webview_user_agent: String?
    public var locale: String?
    public var model: String?
    public var manufacturer: String?
}

public class GetUnreadCountResponse: Codable {
    var status: String?
    var message: String?
    var response: GetUnreadCountResponseData?
}

public class GetUnreadCountResponseData: Codable {
    var unread_counter: Int?
}
