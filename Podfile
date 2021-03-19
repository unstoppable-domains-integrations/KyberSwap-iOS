platform :ios, '11.0'
inhibit_all_warnings!
source 'https://github.com/CocoaPods/Specs.git'

target 'KyberNetwork' do
  use_frameworks!

  pod 'BigInt', '~> 3.1.0'
  pod 'JSONRPCKit', '~> 3.0.0' #:git=> 'https://github.com/bricklife/JSONRPCKit.git'
  pod 'APIKit', '~> 3.2.1'
  pod 'Eureka', '~> 5.3.0'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'StatefulViewController', '~> 3.0'
  pod 'QRCodeReaderViewController', '~> 4.0.2' #:git=>'https://github.com/yannickl/QRCodeReaderViewController.git', :branch=>'master'
  pod 'KeychainSwift', '~> 13.0.0'
  pod 'SwiftLint', '~> 0.29.4'
  pod 'SeedStackViewController'
  pod 'RealmSwift', '~> 3.19.0'
  pod 'Lokalise', '~> 0.8.1'
  pod 'Moya', '~> 10.0.1'
  pod 'JavaScriptKit', '~> 1.0.0'
  pod 'CryptoSwift', '~> 1.0'
  pod 'Kingfisher', '~> 5.13'
  pod 'TrustCore', '~> 0.0.7'
  pod 'TrustKeystore', '~> 0.4.2'
  pod 'WalletConnect', git: 'https://github.com/trustwallet/wallet-connect-swift', branch: 'master'
  # pod 'web3swift', :git=>'https://github.com/BANKEX/web3swift', :branch=>'master'
  pod 'SAMKeychain', '~> 1.5.3'
  pod 'IQKeyboardManager', '~> 6.5'
  pod 'SwiftMessages', '~> 5.0.1'
  pod 'SwiftChart', '~> 1.0.1'
  pod 'JdenticonSwift', '~> 0.0.1'
  pod 'MSCircularSlider', '~> 1.2.2'
  pod 'EasyTipView', '~> 2.0.1'
  pod 'OneSignal', '>= 2.11.2', '< 3.0'
  pod 'UnstoppableDomainsResolution', '~> 0.3.5'
  
  pod 'FBSDKLoginKit/Swift'
  pod 'FBSDKLoginKit/Swift'
  pod 'GoogleSignIn', '~> 5.0.2'
  pod 'TwitterKit5'
  pod 'Starscream', '~> 3.1'
  pod 'Firebase', '~> 6.26'
  pod 'FirebaseCore', '~> 6.7'
  pod 'FirebaseAnalytics', '~> 6.6'
  pod 'FirebaseCrashlytics', '~> 4.1'
  pod 'FirebaseRemoteConfig', '~> 4.4'
  pod 'SwipeCellKit'
  pod 'Charts'
  pod 'FreshchatSDK', '~> 4.0'
  pod 'FSPagerView'

  target 'KyberNetworkTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'KyberNetworkUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['TrustKeystore'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
      end
    end
  end
end
