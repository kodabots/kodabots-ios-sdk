//
//  KodaBotsRestApi.swift
//  KodaBotsSDK
//
//  Created by Felislynx.Silae on 16/10/2020.
//  Copyright © 2020 KodaBots. All rights reserved.
//

import Foundation

public final class KodaBotsRestApi {

    private let client = NetworkClient()
    public static let shared = KodaBotsRestApi()

    private init(){}

    func getUnreadCount(onResponse: @escaping ((GetUnreadCountResponse?, FailReason?, String?) -> Void)) {
        guard
            let url = URL(string:"\(Config.shared.REST_BASE_URL)/sdk/\(Config.shared.REST_API_VERSION)/unread-counter")
        else {
            return
        }
        return client.call(
            request: Request(
                url: url,
                method: RESTMethod.GET,
                payload: nil,
                headers: [
                    "kodabots-bot-token": KodaBotsSDK.shared.clientToken ?? "",
                    "kodabots-bot-user-id": KodaBotsPreferences.shared.getUserId() ?? ""
                ],
                queryItems: [:]
            ),
            onResponse: {(response) in
                do {
                    switch response {
                    case .SUCCESS(let data):
                        guard let data else { return }
                        let userInfoResponse = try JSONDecoder().decode(GetUnreadCountResponse.self, from: data)
                        onResponse(userInfoResponse, nil, nil)
                    case .ERROR(let error):
                        print("KodaBotsSDK -> Error "+error.localizedDescription)
                        onResponse(nil, .OTHER, error.localizedDescription)
                    default:
                        onResponse(nil, .OTHER, "")
                    }
                } catch {
                    print("KodaBotsSDK -> Error "+error.localizedDescription)
                    onResponse(nil, .PARSE_EXCEPTION, nil)
                }
            }
        )
    }
}
final class NetworkClient {
    func call(request:Request, onResponse: @escaping ((Response) -> Void)) {
        var components = URLComponents(string: request.url.absoluteString)

        if request.queryItems.count > 0 {
            components?.queryItems = request.queryItems.map { (key, value) in
                URLQueryItem(name: key, value: value)
            }
        }
        guard let url = components?.url else { return }
        var sessionRequest = URLRequest(url: url)

        sessionRequest.httpMethod = "\(request.method)"
        request.headers.keys.forEach { key in
            guard let value = request.headers[key] else { return }
            sessionRequest.addValue(value, forHTTPHeaderField: key)
        }

        if let payload = request.payload {
            sessionRequest.httpBody = payload
        }

        let networkCall = URLSession.shared.dataTask(with: sessionRequest) { data, response, error in
            let httpResponse = response as? HTTPURLResponse
            if let error = error {
                onResponse(Response.ERROR(error))
                return
            }
            if 200 ... 299 ~= httpResponse?.statusCode ?? -1{
                onResponse(Response.SUCCESS(data))
            } else if 401 ~= httpResponse?.statusCode ?? -1 {
                onResponse(Response.UNAUTHORIZED)
            } else if 400 ~= httpResponse?.statusCode ?? -1 {
                onResponse(Response.ERROR(NSError(domain: "Response not in 200-299 code, actual code is \(httpResponse?.statusCode ?? -1)", code: 0, userInfo: nil)))
            } else {
                var errorMessage = ""
                if let data {
                    errorMessage = String(data: data, encoding: .utf8) ?? ""
                }
                onResponse(Response.ERROR(NSError(domain: "Response not in 200-299 code, actual code is \(httpResponse?.statusCode ?? -1) \(errorMessage)", code: 0, userInfo: nil)))
            }
        }
        networkCall.resume()
    }
}

struct Request {
    let url: URL
    let method:RESTMethod
    let payload:Data?
    let headers:[String:String]
    let queryItems:[String:String]
}

enum Response {
    case SUCCESS(Data?)
    case ERROR(Error)
    case UNAUTHORIZED
}

enum FailReason: String {
    case NETWORK
    case UNAUTHORIZED
    case PARSE_EXCEPTION
    case OTHER
}
enum RESTMethod {
    case POST
    case GET
}
