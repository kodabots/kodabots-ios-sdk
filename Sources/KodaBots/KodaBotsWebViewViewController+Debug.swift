import WebKit

// MARK: - Web debug (KBSettings.webDebugEnabled)

extension KodaBotsWebViewViewController {

	var isWebDebugEnabled: Bool {
		KodaBotsSDK.shared.settings?.webDebugEnabled == true
	}

	func setupWebDebug(handler: WKScriptMessageHandler) {
		guard isWebDebugEnabled else { return }
		if #available(iOS 16.4, *) {
			webView.isInspectable = true
		}
		let contentController = webView.configuration.userContentController
		contentController.add(handler, name: K.handlerName)
		contentController.addUserScript(
			WKUserScript(source: K.script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
		)
		printWebDebug("web debug enabled")
	}

	func handleWebDebugMessage(_ body: [String: Any?]) {
		let type = body["type"] as? String ?? "?"
		let payload = body["payload"] as? String ?? ""
		printWebDebug("[\(type)] \(payload)")
	}

	func printWebDebug(_ message: String) {
		guard isWebDebugEnabled else { return }
		print("🤖KodaBotsSDK 🌐 -> \(message)")
	}

	/**
	 * Debug only, requires `KBSettings.webDebugEnabled`.
	 * Runs `script` as the body of an async JS function in the page (`await` and `return` are allowed)
	 * and returns the result description.
	 */
	public func evaluateDebugJavaScript(_ script: String, completion: @escaping (String) -> Void) {
		guard isWebDebugEnabled else {
			completion("webDebugEnabled is false")
			return
		}
		webView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
			switch result {
			case .success(let value):
				completion("\(value)")
			case .failure(let error):
				completion("error: \(error)")
			}
		}
	}

	static var webDebugHandlerName: String { K.handlerName }
}

// MARK: - Constants (private)

private enum K {
	static let handlerName = "kbDebug"

	static let script = """
	(function () {
		if (window.__kbDebugInstalled) { return; }
		window.__kbDebugInstalled = true;

		function send(type, payload) {
			try { window.webkit.messageHandlers.kbDebug.postMessage({ type: type, payload: String(payload) }); } catch (_) {}
		}
		function format(args) {
			return Array.prototype.map.call(args, function (arg) {
				if (typeof arg === 'string') { return arg; }
				if (arg instanceof Error) { return arg.name + ': ' + arg.message; }
				try { return JSON.stringify(arg); } catch (_) { return String(arg); }
			}).join(' ');
		}
		function truncate(value) {
			if (value === null || value === undefined) { return String(value); }
			var string = String(value);
			return string.length > 1000 ? string.slice(0, 1000) + '…(' + string.length + ' chars)' : string;
		}

		['log', 'info', 'warn', 'error', 'debug'].forEach(function (level) {
			var original = console[level];
			console[level] = function () {
				send('console.' + level, format(arguments));
				return original.apply(console, arguments);
			};
		});

		window.addEventListener('error', function (event) {
			send('js.error', event.message + ' @ ' + event.filename + ':' + event.lineno);
		});
		window.addEventListener('unhandledrejection', function (event) {
			send('js.unhandledrejection', format([event.reason]));
		});

		var storage = Storage.prototype;
		var setItem = storage.setItem, getItem = storage.getItem, removeItem = storage.removeItem, clear = storage.clear;
		function storageName(target) { return target === window.sessionStorage ? 'sessionStorage' : 'localStorage'; }
		storage.setItem = function (key, value) {
			send(storageName(this) + '.set', key + ' = ' + truncate(value));
			return setItem.apply(this, arguments);
		};
		storage.getItem = function (key) {
			var value = getItem.apply(this, arguments);
			// The chatbot probes storage availability with getItem('test') before every access.
			if (key === 'test') { return value; }
			send(storageName(this) + '.get', key + ' -> ' + truncate(value));
			return value;
		};
		storage.removeItem = function (key) {
			send(storageName(this) + '.remove', key);
			return removeItem.apply(this, arguments);
		};
		storage.clear = function () {
			send(storageName(this) + '.clear', '');
			return clear.apply(this, arguments);
		};

		send('page', 'debug script injected into ' + location.href);
	})();
	"""
}
