# Koda Bots SDK(SPM)
![SwiftPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)

This repo provides Swift Package Manager support for [KodaBotsSDK](https://github.com/kodabots/kodabots-ios-sdk)

## Installation guide
To install KodaBots using Swift Package Manager you can follow the [tutorial published by Apple](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) using the URL for this repo with the current version:
1. In Xcode, select “File” → “Add Packages...”
1. Enter https://github.com/kodabots/kodabots-ios-sdk.git

or you can add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/kodabots/kodabots-ios-sdk.git", from: "1.5.0")
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

From version `1.5.0` it's possible to initialize KodaBots SDK without info.plist declaration. To initialize use ```KodaBotsSDK.shared.initialize(with settings: KBSettings)``` where ```KBSettings``` includes informations: ```clientID```, ```serverType``` and ```debugEnabled```.

### Debugging
From version `1.5.0` debug messages from package are disabled, to enable use ```KodaBotsSDK.shared.initialize(debugMessagesEnabled: true)``` or set it on ```KBSettings```.

## Methods overview
- ```getUnreadCount``` is available without initialization of webview, inside ```KodaBotsSDK```, returns unread count of messages
- ```sendBlock``` is available after initialization of webview, inside ```KodaBotsWebViewViewController```, returns true if send to webview, false if not initialized
- ```syncUserProfile``` is available after initialization of webview, inside ```KodaBotsWebViewViewController```, returns true if send to webview, false if not initialized

## External Dependencies
KodaBots use  [lottie-ios](https://github.com/airbnb/lottie-ios) for animation. There is also an option to set custom loading using lottie. 

*Default loader: https://lottiefiles.com/36219-loader
Thanks to Sinan Özkök, creator of loader
