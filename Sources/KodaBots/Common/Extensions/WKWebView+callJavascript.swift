import Foundation
import WebKit
import JavaScriptCore

extension WKWebView {
	func callJavascript(data:String){
		printIfNeeded(message: "Calling Javascript: \(data)", priority: .info)
		let requestString = "\(data)"
		self.evaluateJavaScript(requestString)
	}
}
