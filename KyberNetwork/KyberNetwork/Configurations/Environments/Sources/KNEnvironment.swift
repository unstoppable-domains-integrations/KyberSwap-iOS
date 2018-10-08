// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNEnvironment: Int {

  case mainnetTest = 0
  case production = 1
  case staging = 2
  case ropsten = 3
  case kovan = 4

  var displayName: String {
    switch self {
    case .mainnetTest: return "Mainnet"
    case .production: return "Production"
    case .staging: return "Staging"
    case .ropsten: return "Ropsten"
    case .kovan: return "Kovan"
    }
  }

  static func allEnvironments() -> [KNEnvironment] {
    return [
      KNEnvironment.mainnetTest,
      KNEnvironment.production,
      KNEnvironment.staging,
      KNEnvironment.ropsten,
      KNEnvironment.kovan,
    ]
  }

  static let internalBaseEndpoint: String = {
    return KNAppTracker.internCachedEnpoint()
  }()

  static let internalTrackerEndpoint: String = {
    return KNAppTracker.internalTrackerEndpoint()
  }()

  static var `default`: KNEnvironment {
    return KNAppTracker.externalEnvironment()
  }

  var chainID: Int {
    return self.customRPC?.chainID ?? 0
  }

  var etherScanIOURLString: String {
    return self.knCustomRPC?.etherScanEndpoint ?? ""
  }

  var customRPC: CustomRPC? {
    return self.knCustomRPC?.customRPC
  }

  var knCustomRPC: KNCustomRPC? {
    guard let json = KNJSONLoaderUtil.jsonDataFromFile(with: self.configFileName) else {
      return nil
    }
    return KNCustomRPC(dictionary: json)
  }

  var configFileName: String {
    switch self {
    case .mainnetTest: return "config_env_mainnet_test"
    case .production: return "config_env_production"
    case .staging: return "config_env_staging"
    case .ropsten: return "config_env_ropsten"
    case .kovan: return "config_env_kovan"
    }
  }

  var apiEtherScanEndpoint: String {
    switch self {
    case .mainnetTest: return "http://api.etherscan.io/"
    case .production: return "http://api.etherscan.io/"
    case .staging: return "http://api-kovan.etherscan.io/"
    case .ropsten: return "http://api-ropsten.etherscan.io/"
    case .kovan: return "http://api-kovan.etherscan.io/"
    }
  }
}
