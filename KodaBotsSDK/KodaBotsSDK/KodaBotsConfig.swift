//
//  KodaBotsConfig.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 25/02/2021.
//  Copyright © 2021 KodaBots. All rights reserved.
//

import Foundation
import Lottie

public class KodaBotsConfig {
    public init() {}
    public var userProfile = UserProfile()
    public var blockId:String?
    public var progressConfig:KodaBotsProgressConfig?
    public var timeoutConfig:KodaBotsTimedOutConfig?
}

public class KodaBotsProgressConfig {
    public init() {}
    public var backgroundColor:UIColor?
    public var progressColor:UIColor?
    public var customAnimation: Animation?
}

public class KodaBotsTimedOutConfig {
    public init() {}
    public var timeout:DispatchTimeInterval?
    public var image:UIImage?
    public var backgroundColor:UIColor?
    public var buttonText:String?
    public var buttonColor:UIColor?
    public var buttonTextColor:UIColor?
    public var buttonFont:UIFont?
    public var buttonFontSize:Float?
    public var buttonCornerRadius:Float?
    public var buttonBorderWidth:Float?
    public var buttonBorderColor:UIColor?
    public var message:String?
    public var messageTextColor:UIColor?
    public var messageFont:UIFont?
    public var messageFontSize:Float?
}
