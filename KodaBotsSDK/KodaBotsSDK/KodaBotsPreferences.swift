//
//  KodaBotsPreferences.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 09/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import Foundation
public final class KodaBotsPreferences {
    
    public static let shared = KodaBotsPreferences()
    private init(){}
    private let userPreferences = UserDefaults.standard
    
    private static let KEY_USER_ID = "KEY_USER_ID"
    func setUserId(userId:String?){
        userPreferences.set(userId, forKey: KodaBotsPreferences.KEY_USER_ID)
    }
    
    func getUserId()->String?{
        return userPreferences.string(forKey: KodaBotsPreferences.KEY_USER_ID)
    }
    
}
