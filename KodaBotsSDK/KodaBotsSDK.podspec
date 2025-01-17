
Pod::Spec.new do |spec|

  spec.name             = "KodaBotsSDK"
  spec.version          = "1.3.2"
  spec.summary          = "SDK for KODA Bots"
  spec.description      = "SDK for KODA Bots for iOS"
  spec.homepage         = "https://kodabots.com/"
  spec.swift_version    = "5.0"
  spec.license          = { :type => "MIT", :file => "LICENSE" }
  spec.author           = { "KODA sp. z o.o." => "it@koda.ai" }
  spec.platform         = :ios, "12.0"

  spec.source              = { :path => "." }
  spec.source_files = "KodaBotsSDK/**/*.{h,m,swift}"
  spec.resources = "KodaBotsSDK/**/*.{xib,storyboard,json,png,xcassets,strings}"
  spec.resource_bundles = {
	'KodaBotsSDK' => ['KodaBotsSDK/**/*.{xib,storyboard,json,png,xcassets,strings}']
  }
  spec.ios.framework  = 'WebKit'
  spec.dependency 'lottie-ios', '~> 3.1.8'

  spec.documentation_url = "https://docs.kodabots.com"

end
