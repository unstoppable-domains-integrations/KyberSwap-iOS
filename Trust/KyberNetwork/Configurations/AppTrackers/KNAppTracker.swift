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
  static let kInternalTrackerEndpointKey: String = "kInternalTrackerEndpointKey"
  static let kExternalEnvironmentKey: String = "kExternalEnvironmentKey"

  static let kTransactionLoadStateKey: String = "kTransactionLoadStateKey"

  static let kSupportedLoadingTimeKey: String = "kSupportedLoadingTimeKey"

  static let kBalanceDisplayDataTypeKey: String = "kBalanceDisplayDataTypeKey"
  static let kTokenListDisplayDataTypeKey: String = "kTokenListDisplayDataTypeKey"

  static let userDefaults: UserDefaults = UserDefaults.standard

  static func internalTrackerEndpoint() -> String {
    if let value = userDefaults.object(forKey: kInternalTrackerEndpointKey) as? String {
      return value
    }
    return "https://tracker.kyber.network"
  }

  static func updateInternalTrackerEndpoint(value: String) {
    userDefaults.set(value, forKey: kInternalTrackerEndpointKey)
    userDefaults.synchronize()
  }

  // MARK: Internal cache endpoint key
  static func internalCacheEndpoint() -> String {
    if let value = userDefaults.object(forKey: kInternalCacheEndpointKey) as? String {
      return value
    }
    return "https://production-cache.kyber.network"
  }

  static func updateInternalCacheEndpoint(value: String) {
    userDefaults.set(value, forKey: kInternalCacheEndpointKey)
    userDefaults.synchronize()
  }

  // MARK: External environment
  static func externalEnvironment() -> KNEnvironment {
    if let value = userDefaults.object(forKey: kExternalEnvironmentKey) as? Int, let env = KNEnvironment(rawValue: value) {
      return env
    }
    return KNEnvironment.mainnetTest
  }

  static func updateExternalEnvironment(_ env: KNEnvironment) {
    userDefaults.set(env.rawValue, forKey: kExternalEnvironmentKey)
    userDefaults.synchronize()
  }

  // MARK: Transaction load state
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

  // MARK: Supported Tokens
  static func updateSuccessfullyLoadSupportedTokens() {
    let time = Date().timeIntervalSince1970
    userDefaults.set(time, forKey: kSupportedLoadingTimeKey)
    userDefaults.synchronize()
  }

  static func getSuccessfullyLoadSupportedTokensDate() -> Date? {
    guard let time = userDefaults.value(forKey: kSupportedLoadingTimeKey) as? Double else {
      return nil
    }
    return Date(timeIntervalSince1970: time)
  }

  // MARK: Balance currency (USD or ETH)
  static func updateBalanceDisplayDataType(_ type: KNBalanceDisplayDataType) {
    userDefaults.set(type.rawValue, forKey: kBalanceDisplayDataTypeKey)
    userDefaults.synchronize()
  }

  static func getBalanceDisplayDataType() -> KNBalanceDisplayDataType {
    if let type = userDefaults.object(forKey: kBalanceDisplayDataTypeKey) as? String {
      return KNBalanceDisplayDataType(rawValue: type) ?? .usd
    }
    return .usd
  }

  // MARK: Token display type
  static func updateTokenListDisplayDataType(_ type: KNTokensDisplayType) {
    userDefaults.set(type.rawValue, forKey: kTokenListDisplayDataTypeKey)
    userDefaults.synchronize()
  }

  static func getTokenListDisplayDataType() -> KNTokensDisplayType {
    if let type = userDefaults.object(forKey: kTokenListDisplayDataTypeKey) as? String {
      return KNTokensDisplayType(rawValue: type) ?? .change24h
    }
    return .change24h
  }

  // MARK: Reset app tracker
  static func resetAppTrackerData(for address: Address) {
    self.updateTransactionLoadState(.none, for: address)
  }

  static func resetAllAppTrackerData() {
    userDefaults.removeObject(forKey: kSupportedLoadingTimeKey)
    userDefaults.removeObject(forKey: kBalanceDisplayDataTypeKey)
    userDefaults.removeObject(forKey: kTokenListDisplayDataTypeKey)
  }
}
