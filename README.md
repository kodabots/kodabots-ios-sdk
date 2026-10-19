# Koda Bots SDK (SPM)
![SwiftPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)

Swift Package Manager version of [KodaBotsSDK](https://github.com/kodabots/kodabots-ios-sdk). It shows the KODA chatbot in your iOS app.

## Requirements

- iOS 14 or newer (since `1.6.0`; older versions support iOS 13)

## Installation

In Xcode: **File → Add Packages…** and enter:

```
https://github.com/kodabots/kodabots-ios-sdk.git
```

Or add it to `Package.swift`:

```swift
.package(url: "https://github.com/kodabots/kodabots-ios-sdk.git", from: "1.6.0")
```

```swift
dependencies: [
  .product(name: "KodaBots", package: "kodabots-ios-sdk")
]
```

## Info.plist

Add these privacy descriptions:
- `Privacy - Camera Usage Description`
- `Privacy - Photo Library Usage Description`
- `Privacy - Microphone Usage Description` (only if you use audio)

If you configure the SDK in `Info.plist` (see below), also add a `KodaBotsSDK` dictionary with:
- `clientToken` – your bot token
- `server` – `RELEASE` or `STAGE`

## Quick start

```swift
import KodaBots

// 1. Initialize once, e.g. at app start
let settings = KBSettings(clientToken: "your_token", server: .release)
_ = KodaBotsSDK.shared.initialize(with: settings)

// 2. Create the chat screen and show it
let config = KodaBotsConfig()
if let chat = KodaBotsSDK.shared.generateViewController(config: config, callbacks: { event in
    print(event)
}) {
    present(chat, animated: true)
}
```

You can also initialize from `Info.plist` with `KodaBotsSDK.shared.initialize()`. It returns `false` if the `KodaBotsSDK` entry is missing.

## Keeping the conversation

From `1.6.0`:

- **The conversation stays** after the user closes the chat screen or restarts the app.
- **On logout, call `clearCache()`.** Otherwise the next user sees the previous conversation. Call it when the chat screen is closed.

```swift
KodaBotsSDK.shared.clearCache {
    // conversation removed
}
```

### Same user across devices

Pass your own user ID (max 36 characters). The chatbot will treat it as the same user every time, also on a new device or after a reinstall.

```swift
let config = KodaBotsConfig()
config.userProfile.id = currentUser.id
```

The message history on the screen is stored on the device, so it is **not** shown on a new device.

### For the chatbot web page

The SDK gives the chatbot page two functions to save text (e.g. JSON) on the device. Both return a `Promise`.

```js
// read: returns a string or null
const session = await window.webkit.messageHandlers.readCache.postMessage({ key: "session" });

// save: value must be a string; null deletes the key
await window.webkit.messageHandlers.saveCache.postMessage({ key: "session", value: JSON.stringify(data) });
```

Only the chatbot page itself can use them. Calls from iframes or other websites are rejected.

## Settings (`KBSettings`)

| Setting | What it does | Default |
|---|---|---|
| `clientToken` | Your bot token | `""` |
| `server` | `.release` or `.stage` | `.release` |
| `path` | Your own hosts (see below) | `nil` |
| `debugMessagesEnabled` | SDK logs in the Xcode console | `false` |
| `webDebugEnabled` | Chat page logs and Safari Web Inspector (see below) | `false` |

### Custom hosts

Use this to connect to another environment. Set it once, when you initialize the SDK.

```swift
let path = KodaURL(
    base: "https://web.staging.example.com",   // chat page
    baseVersion: "v1",
    rest: "https://bot.staging.example.com",   // API
    restVersion: "v1"
)
_ = KodaBotsSDK.shared.initialize(with: KBSettings(clientToken: "your_token", path: path))
```

Without `path`, the SDK uses its own hosts for `server`.

### Debugging

- `debugMessagesEnabled: true` – shows SDK logs in the Xcode console.
- `webDebugEnabled: true` – also shows what happens inside the chat page (console, errors, saved data, messages to the app), marked with `🌐`. You can inspect the page in Safari → Develop (iOS 16.4+).

Use both only in debug builds. Do not ship them in production.

## Methods

In `KodaBotsSDK` (no chat screen needed):
- `getUnreadCount` – number of unread messages
- `clearCache` – deletes the saved conversation

In `KodaBotsWebViewViewController` (chat screen must be loaded, return `false` otherwise):
- `sendBlock` – opens a given conversation block
- `syncUserProfile` – updates user data in the chat

## Dependencies

[lottie-ios](https://github.com/airbnb/lottie-ios) is used for the loading animation. You can set your own Lottie animation in `KodaBotsConfig`.

Default loader: https://lottiefiles.com/36219-loader – thanks to Sinan Özkök.
