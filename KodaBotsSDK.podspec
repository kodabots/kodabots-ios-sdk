Pod::Spec.new do |spec|

  spec.name             = "KodaBotsSDK"
  spec.version          = "1.3.1"
  spec.summary          = "SDK for KODA Bots"
  spec.description      = "SDK for KODA Bots for iOS"
  spec.homepage         = "https://kodabots.com/"
  spec.swift_version    = "5.0"
  spec.license          = { :type => "MIT", :file => "LICENSE" }
  spec.author           = { "KODA sp. z o.o." => "it@koda.ai" }
  spec.platform         = :ios, "12.0"

  spec.source           = { :git => "https://github.com/kodabots/kodabots-ios-sdk.git", :tag => spec.version }
  spec.source_files     = "KodaBotsSDK/KodaBotsSDK/**/*.swift"
  spec.resource_bundles = {
    'KodaBotsSDK' => ['KodaBotsSDK/KodaBotsSDK/**/*.{xib,storyboard,json,png,xcassets,strings}']
  }

  spec.ios.framework    = 'WebKit'
  spec.dependency 'lottie-ios', '~> 3.1.8'

  spec.documentation_url = "https://docs.kodabots.com"

end
