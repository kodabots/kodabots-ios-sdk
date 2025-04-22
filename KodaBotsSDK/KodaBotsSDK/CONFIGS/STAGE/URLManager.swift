//
//  Config.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 12/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import Foundation

public class URLManager {

    // MARK: - Properties (public)

    public static let shared = URLManager()

    public var type: ServerType = .release

    // MARK: - Properties

    var base: String {
        switch type {
        case .release:
            return K.Release.base
        case .stage:
            return K.Stage.base
        }
    }

    var baseVersion: String {
        switch type {
        case .release:
            return K.Release.baseVersion
        case .stage:
            return K.Stage.baseVersion
        }
    }

    var rest: String {
        switch type {
        case .release:
            return K.Release.rest
        case .stage:
            return K.Stage.rest
        }
    }

    var restVersion: String {
        switch type {
        case .release:
            return K.Release.restVersion
        case .stage:
            return K.Stage.restVersion
        }
    }

    // MARK: - Lifecycle (private)

    private init() {
        let plist = Bundle.main.object(forInfoDictionaryKey: "KodaBotsSDK") as? [String:Any]
        guard let plist else { return }
        guard let server = plist["server"] as? String? else { return }
        if server == "STAGE" {
            type = .stage
        } else {
            type = .release
        }
    }
}

// MARK: - ServerType (public)

public enum ServerType {
    case stage
    case release
}

// MARK: - Constants (private)

private enum K {
    enum Release {
        static let base = "https://web.eu-pl.koda.ai"
        static let baseVersion = "v1"
        static let rest = "https://bot.eu-pl.koda.ai"
        static let restVersion = "v1"
    }

    enum Stage {
        static let base = "https://web.staging.koda.ai"
        static let baseVersion = "v1"
        static let rest = "https://bot.staging.koda.ai"
        static let restVersion = "v1"
    }
}
