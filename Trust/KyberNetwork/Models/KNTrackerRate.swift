// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import BigInt

class KNTrackerRate: Object {
  @objc dynamic var timestamp: Double = 0.0
  @objc dynamic var tokenName: String = ""
  @objc dynamic var tokenSymbol: String = ""
  @objc dynamic var tokenDecimals: Int = 0
  @objc dynamic var tokenAddress: String = ""
  @objc dynamic var rateETHNow: Double = 0.0
  @objc dynamic var changeETH24h: Double = 0.0
  @objc dynamic var rateUSDNow: Double = 0.0
  @objc dynamic var changeUSD24h: Double = 0.0

  convenience init(dict: JSONDictionary) {
    self.init()
    self.timestamp = dict["timestamp"] as? Double ?? 0.0
    self.tokenName = dict["token_name"] as? String ?? ""
    self.tokenSymbol = dict["token_symbol"] as? String ?? ""
    self.tokenDecimals = dict["token_decimal"] as? Int ?? 0
    self.tokenAddress = dict["token_address"] as? String ?? ""
    self.rateETHNow = dict["rate_eth_now"] as? Double ?? 0.0
    self.changeETH24h = dict["change_eth_24h"] as? Double ?? 0.0
    self.changeUSD24h = dict["change_usd_24h"] as? Double ?? 0.0
    self.rateUSDNow = dict["rate_usd_now"] as? Double ?? 0.0
  }

  convenience init(ieoObject: IEOObject) {
    self.init()
    self.timestamp = Date().timeIntervalSince1970
    self.tokenName = ieoObject.tokenName
    self.tokenSymbol = ieoObject.tokenSymbol
    self.tokenAddress = ieoObject.tokenAddr
    self.tokenDecimals = ieoObject.tokenDecimals
    let rateDouble: Double = {
      let rateBigInt = ieoObject.rate.fullBigInt(decimals: ieoObject.tokenDecimals) ?? BigInt(0)
      return rateBigInt.isZero ? 0.0 : Double(BigInt(10).power(ieoObject.tokenDecimals)) / Double(rateBigInt)
    }()
    self.rateETHNow = rateDouble
    self.changeETH24h = 0.0
    if let ethTrackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) {
      self.rateUSDNow = self.rateETHNow * ethTrackerRate.rateUSDNow
    } else {
      self.rateUSDNow = 0.0
    }
    self.changeUSD24h = 0.0
  }

  var rateETHBigInt: BigInt {
    return BigInt(self.rateETHNow * Double(EthereumUnit.ether.rawValue))
  }

  var rateUSDBigInt: BigInt {
    return BigInt(self.rateUSDNow * Double(EthereumUnit.ether.rawValue))
  }

  override static func primaryKey() -> String {
    return "tokenAddress"
  }
}

extension KNTrackerRate {
  func isTrackerRate(for token: TokenObject) -> Bool {
    if KNEnvironment.default == .kovan || KNEnvironment.default == .ropsten {
      return self.tokenSymbol == token.symbol
    }
    return self.tokenAddress.lowercased() == token.contract.lowercased()
  }

  var identifier: String {
    if KNEnvironment.default == .kovan || KNEnvironment.default == .ropsten {
      return self.tokenSymbol
    }
    return self.tokenAddress.lowercased()
  }
}
