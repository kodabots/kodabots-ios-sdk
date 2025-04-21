import Foundation

public class UserProfile: NSObject, Codable {
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var os: String?
    public var osVersion: String?
    public var webviewUserAgent: String?
    public var locale: String?
    public var model: String?
    public var manufacturer: String?
    public var customParameters: [String:String] = [:]

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email = "email"
        case os = "os"
        case osVersion = "os_version"
        case webviewUserAgent = "webview_user_agent"
        case locale = "locale"
        case model = "model"
        case manufacturer = "manufacturer"
        case customParameters = "custom_parameters"
    }
}
