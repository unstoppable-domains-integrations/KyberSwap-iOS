// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import RealmSwift
import TrustKeystore
import TrustCore

struct RealmConfiguration {

    static func configuration(for account: Wallet, chainID: Int) -> Realm.Configuration {
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("\(account.address.description.lowercased())-\(chainID).realm")
        return config
    }

    static func globalConfiguration(for chainID: Int? = nil) -> Realm.Configuration {
      let id: String = {
        if let chainID = chainID { return "\(chainID)" }
        return ""
      }()
      var config = Realm.Configuration()
      config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("kybernetworkwallet-global-\(id).realm")
      return config
    }
}
