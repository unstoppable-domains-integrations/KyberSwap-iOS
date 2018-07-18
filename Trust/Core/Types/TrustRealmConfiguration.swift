// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import RealmSwift
import TrustKeystore
import TrustCore

struct RealmConfiguration {

    static func configuration(for account: Wallet, chainID: Int = KNEnvironment.default.chainID) -> Realm.Configuration {
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("\(account.address.description.lowercased())-\(chainID).realm")
        return config
    }

    static func globalConfiguration(for chainID: Int = KNEnvironment.default.chainID) -> Realm.Configuration {
      var config = Realm.Configuration()
      config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("kybernetworkwallet-global-\(chainID).realm")
      return config
    }

  static func kyberGOConfiguration(for userID: Int, chainID: Int = KNEnvironment.default.chainID) -> Realm.Configuration {
      var config = Realm.Configuration()
      config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("kybernetworkwallet-kybergo-\(userID)-\(chainID).realm")
      return config
    }
}
