import Foundation

public struct KodaURL {
	let base: String
	let baseVersion: String
	let rest: String
	let restVersion: String

	public init(base: String, baseVersion: String, rest: String, restVersion: String) {
		self.base = base
		self.baseVersion = baseVersion
		self.rest = rest
		self.restVersion = restVersion
	}
}
