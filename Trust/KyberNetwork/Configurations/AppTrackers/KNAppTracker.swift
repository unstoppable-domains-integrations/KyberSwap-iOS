// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore

enum KNTransactionLoadState: Int {
  case none = 0
  case done = 1
  case failed = 2
}

class KNAppTracker {

  // Env
  static let kInternalCacheEndpointKey: String = "kInternalCacheEndpointKey"
  static let kExternalEnvironmentKey: String = "kExternalEnvironmentKey"

  static let kTransactionLoadStateKey: String = "kTransactionLoadStateKey"

  static let userDefaults: UserDefaults = UserDefaults.standard

  // Internal cache endpoint key
  static func internalCacheEndpoint() -> String {
    if let value = userDefaults.object(forKey: kInternalCacheEndpointKey) as? String {
      return value
    }
    return isDebug ? "https://staging-cache.kyber.network" : "https://production-cache.kyber.network"
  }

  static func updateInternalCacheEndpoint(value: String) {
    userDefaults.set(value, forKey: kInternalCacheEndpointKey)
    userDefaults.synchronize()
  }

  // External environment
  static func externalEnvironment() -> KNEnvironment {
    if let value = userDefaults.object(forKey: kExternalEnvironmentKey) as? Int, let env = KNEnvironment(rawValue: value) {
      return env
    }
    return isDebug ? KNEnvironment.kovan : KNEnvironment.mainnetTest
  }

  static func updateExternalEnvironment(_ env: KNEnvironment) {
    userDefaults.set(env.rawValue, forKey: kExternalEnvironmentKey)
    userDefaults.synchronize()
  }

  // Transaction load state
  static func transactionLoadState(for address: Address) -> KNTransactionLoadState {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionLoadStateKey + sessionID
    if let value = userDefaults.object(forKey: key) as? Int {
      return KNTransactionLoadState(rawValue: value) ?? .none
    }
    return .none
  }

  static func updateTransactionLoadState(_ state: KNTransactionLoadState, for address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionLoadStateKey + sessionID
    userDefaults.set(state.rawValue, forKey: key)
    userDefaults.synchronize()
  }

  // Reset app tracker
  static func resetAppTrackerDidExitSession(_ session: KNSession) {
    self.updateTransactionLoadState(.none, for: session.wallet.address)
  }
}
