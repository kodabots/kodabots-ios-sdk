import Foundation

extension String {
    func localized(_ bundle: Bundle = .module) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: bundle, comment: "")
    }
}
