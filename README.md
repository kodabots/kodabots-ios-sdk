# Koda Bots SDK
## 1. Installation guide
- From the File menu, select Add Package Dependencies.
- Add ```pod 'KodaBotsSDK'``` into your podfile
- Add ```KodaBotsSDK``` entry into your Info.plist as dictonary, add key ```clientToken``` and it's value
- Add ```Privacy - Microphone Usage Description``` with description into your Info.plist, only when you use audio feature (not available in 1.0.X releases)
- Add ```Privacy - Camera Usage Description``` with description into your Info.plist
- Add ```Privacy - Photo Library Usage Description``` with description into your Info.plist

## 2. Usage guide
- Import KodaBotsSDK
- Invoke ```KodaBotsSDK.shared.initialize()```
- If previous method returned true, you can then call ```KodaBotsSDK.shared.generateViewController(config:KodaBotsConfig?, callbacks:((KodaBotsCallbacks)->Void)?)``` to obtain ViewController which you can insert into your custom view or start as separate view controller

## 3. Methods overview
- getUnreadCount is available without initialization of webview, inside ```KodaBotsSDK```, returns unread count of messages
- sendBlock is available after initialization of webview, inside ```KodaBotsWebViewViewController```, returns true if send to webview, false if not initialized
- syncUserProfile is available after initialization of webview, inside ```KodaBotsWebViewViewController```, returns true if send to webview, false if not initialized



- Default loader: https://lottiefiles.com/36219-loader
Thanks to Sinan Özkök, creator of loader
