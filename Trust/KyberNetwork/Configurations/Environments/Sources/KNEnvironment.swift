// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNEnvironment: Int {

  case mainnetTest = 0
  case production = 1
  case staging = 2
  case ropsten = 3
  case kovan = 4

  static let internalBaseEndpoint: String = {
    return KNAppTracker.internalCacheEndpoint()
  }()

  static var `default`: KNEnvironment {
    return KNAppTracker.externalEnvironment()
  }

  var chainID: Int {
    guard let json = KNJSONLoaderUtil.jsonDataFromFile(with: self.configFileName) else {
      print("---> Error: Can not get json from file name: \(self.configFileName)")
      return 0
    }
    return json["networkId"] as? Int ?? 0
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
}
