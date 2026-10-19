# Koda Bots SDK(SPM)
![SwiftPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)

This repo provides Swift Package Manager support for [KodaBotsSDK](https://github.com/kodabots/kodabots-ios-sdk)

## Installation guide
To install KodaBots using Swift Package Manager you can follow the [tutorial published by Apple](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) using the URL for this repo with the current version:
1. In Xcode, select “File” → “Add Packages...”
1. Enter https://github.com/kodabots/kodabots-ios-sdk.git

or you can add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/kodabots/kodabots-ios-sdk.git", from: "1.6.0")
```

and add it to your target like this:

```swift
dependencies: [
  .product(name: "KodaBots", package: "kodabots-ios-sdk")
]
```

### Configuration `info.plist`
- Add entry into your `info.plist` as dictionary, add ```clientToken``` and ```server``` keys with values (for server: "RELEASE")
- Add ```Privacy - Microphone Usage Description``` with description into your `info.plist`, only when you use audio feature (not available in `1.0.X` releases)
- Add ```Privacy - Camera Usage Description``` with description into your `info.plist`
- Add ```Privacy - Photo Library Usage Description``` with description into your `info.plist`

## Usage guide
- Import `KodaBots`
- Invoke ```KodaBotsSDK.shared.initialize()```
- If method returned true, you can then call ```KodaBotsSDK.shared.generateViewController(config:KodaBotsConfig?, callbacks:((KodaBotsCallbacks)->Void)?)``` to obtain ViewController which you can insert into your custom view or start as separate view controller

### Initialize without info.plist

From version `1.5.0` it's possible to initialize KodaBots SDK without info.plist declaration. To initialize use ```KodaBotsSDK.shared.initialize(with settings: KBSettings)``` where ```KBSettings``` includes informations: ```clientToken```, ```server```, ```debugMessagesEnabled``` and ```path```.

```swift
let settings = KBSettings(
    clientToken: "your_token",
    server: .release,
    debugMessagesEnabled: false
)

KodaBotsSDK.shared.initialize(with: settings)
```

### Custom hosts

From version `1.5.3` it's possible to override the default chatbot and REST API hosts by passing a `path` (`KodaURL`) to `KBSettings`. This is useful for pointing the SDK at a staging environment or a white-label deployment. The override is applied globally for the SDK's entire lifetime — set it once at initialization, before any webview or REST call is made.

```swift
let customPath = KodaURL(
    base: "https://web.staging.example.com",
    baseVersion: "v1",
    rest: "https://bot.staging.example.com",
    restVersion: "v1"
)

let settings = KBSettings(
    clientToken: "your_token",
    path: customPath
)

KodaBotsSDK.shared.initialize(with: settings)
```

When `path` is `nil` (default), the SDK uses its built-in URLs based on `server` (`.release` or `.stage`).

### Debugging
From version `1.5.0` debug messages from package are disabled, to enable use ```KodaBotsSDK.shared.initialize(debugMessagesEnabled: true)``` or set it on ```KBSettings```.

### Web debugging
Set `webDebugEnabled: true` on ```KBSettings``` to log the webview console, JS errors, `localStorage`/`sessionStorage` access and JS ↔ native messages to the Xcode console (prefixed with `🌐`). It also makes the webview inspectable in Safari → Develop (iOS 16.4+) and enables ```KodaBotsWebViewViewController.evaluateDebugJavaScript```. Use it in debug builds only.

## Methods overview
- ```getUnreadCount``` is available without initialization of webview, inside ```KodaBotsSDK```, returns unread count of messages
- ```sendBlock``` is available after initialization of webview, inside ```KodaBotsWebViewViewController```, returns true if send to webview, false if not initialized
- ```syncUserProfile``` is available after initialization of webview, inside ```KodaBotsWebViewViewController```, returns true if send to webview, false if not initialized
- ```clearCache``` is available without initialization of webview, inside ```KodaBotsSDK```, removes conversation cache saved by the webview

## User ID

From version `1.6.0` you can pass a stable user identifier from your app (max 36 characters) as `UserProfile.id`. The chatbot then uses it as the conversation user ID instead of generating a random one, so the same app user is recognized as the same chatbot user on every launch and device.

```swift
let config = KodaBotsConfig()
config.userProfile.id = currentUser.id
```

Note that the visible conversation history is stored on the device by the webview, so it is not restored on a new device or after the webview storage is cleared.

## Conversation cache

From version `1.6.0` the chatbot webview can persist its conversation session in the SDK (`UserDefaults`), so the conversation survives closing the chat screen and restarting the app. The SDK stores plain strings under keys provided by the webview — serializing (e.g. to JSON) is the webview's responsibility.

The webview uses two message handlers, both returning a `Promise`:

```js
// returns string or null
const session = await window.webkit.messageHandlers.readCache.postMessage({ key: "session" });

// value must be a string; null removes the entry
await window.webkit.messageHandlers.saveCache.postMessage({ key: "session", value: JSON.stringify(data) });
```

The cache is shared by all chatbot screens in the app and is not cleared automatically. Call `KodaBotsSDK.shared.clearCache()` when the user logs out, so the next user starts a new conversation.

Version `1.6.0` raises the minimum deployment target to iOS 14.

## External Dependencies
KodaBots use  [lottie-ios](https://github.com/airbnb/lottie-ios) for animation. There is also an option to set custom loading using lottie. 

*Default loader: https://lottiefiles.com/36219-loader
Thanks to Sinan Özkök, creator of loader
