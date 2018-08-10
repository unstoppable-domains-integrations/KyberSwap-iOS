// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore

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
  static let kTransactionNonceKey: String = "kTransactionNonceKey"

  static let kSupportedLoadingTimeKey: String = "kSupportedLoadingTimeKey"

  static let kBalanceDisplayDataTypeKey: String = "kBalanceDisplayDataTypeKey"
  static let kCurrencyTypeKey: String = "kCurrencyTypeKey"
  static let kTokenListDisplayDataTypeKey: String = "kTokenListDisplayDataTypeKey"

  static let userDefaults: UserDefaults = UserDefaults.standard

  static func internalTrackerEndpoint() -> String {
    if let value = userDefaults.object(forKey: kInternalTrackerEndpointKey) as? String {
      return value
    }
    return "https://tracker.kyber.network"//KNEnvironment.default == .ropsten ? "https://staging-tracker.knstats.com" : 
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
    return KNEnvironment.ropsten
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

  static func transactionNonce(for address: Address) -> Int {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionNonceKey + sessionID
    return userDefaults.object(forKey: key) as? Int ?? 0
  }

  static func updateTransactionNonce(_ nonce: Int, address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionNonceKey + sessionID
    userDefaults.set(nonce, forKey: key)
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

  // MARK: Currency used (USD, ETH)
  static func updateCurrencyType(_ type: KWalletCurrencyType) {
    userDefaults.set(type.rawValue, forKey: kCurrencyTypeKey)
    userDefaults.synchronize()
  }

  static func getCurrencyType() -> KWalletCurrencyType {
    if let type = userDefaults.object(forKey: kCurrencyTypeKey) as? String {
      return KWalletCurrencyType(rawValue: type) ?? .usd
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

  // MARK: KyberGO base string
  static func getKyberGOBaseString() -> String {
    return KNEnvironment.default == .ropsten ? "https://dev-userdashboard.knstats.com" : "https://kyber.mangcut.vn"
  }

  // MARK: Reset app tracker
  static func resetAppTrackerData(for address: Address) {
    self.updateTransactionLoadState(.none, for: address)
    self.updateTransactionNonce(0, address: address)
  }

  static func resetAllAppTrackerData() {
    userDefaults.removeObject(forKey: kSupportedLoadingTimeKey)
    userDefaults.removeObject(forKey: kBalanceDisplayDataTypeKey)
    userDefaults.removeObject(forKey: kTokenListDisplayDataTypeKey)
  }
}
