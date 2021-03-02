
Pod::Spec.new do |spec|

  spec.name          = "KodaBotsSDK"
  spec.version       = "1.0.4"
  spec.summary       = "SDK for KODA Bots"
  spec.description   = "SDK for KODA Bots for iOS"
  spec.homepage      = "https://kodabots.com/"
  spec.swift_version = "5.0" 
  spec.license      = "MIT"
  spec.author             = { "FREAM S.A." => "bwyspianski@fream.pl" }
  spec.platform     = :ios, "11.0"

  spec.source              = { :path => "." }
  spec.source_files = "KodaBotsSDK/**/*.{h,m,swift}"
  spec.resources = "KodaBotsSDK/**/*.{xib,storyboard,json,png,xcassets,strings}"
  spec.resource_bundles = {
	'KodaBotsSDK' => ['KodaBotsSDK/**/*.{xib,storyboard,json,png,xcassets,strings}']
  }
  spec.ios.framework  = 'WebKit'
  spec.dependency 'lottie-ios', '~> 3.1.8'

end
