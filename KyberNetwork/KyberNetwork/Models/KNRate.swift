// Copyright SIX DAY LLC. All rights reserved.

import BigInt

// All rate should be in ether unit (18 decimals)
class KNRate: NSObject {

  let source: String
  let dest: String
  let rate: BigInt
  let minRate: BigInt

  init(dictionary: JSONDictionary, isUSDRate: Bool = false) throws {
    if isUSDRate {
      source = dictionary["symbol"] as? String ?? ""
      dest = "USD"
      let rateString: String = dictionary["price_usd"] as? String ?? ""
      if let rateDouble = Double(rateString) {
        rate = BigInt(rateDouble * Double(EthereumUnit.ether.rawValue))
        minRate = rate * BigInt(97) / BigInt(100)
        if isDebug { print("Rate from \(source) to USD: \(EtherNumberFormatter.full.string(from: rate))") }
      } else {
        throw CastError(actualValue: String.self, expectedType: Double.self)
      }
    } else {
      source = dictionary["source"] as? String ?? ""
      let toSymbol = dictionary["dest"] as? String ?? ""
      dest = toSymbol
      let rateString: String = dictionary["rate"] as? String ?? ""
      let minRateString: String = dictionary["minRate"] as? String ?? ""
      if let rateDouble = Double(rateString), let minRateDouble = Double(minRateString),
        let to = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == toSymbol }) {
        rate = BigInt(rateDouble) / BigInt(10).power(18 - to.decimals)
        minRate = BigInt(minRateDouble) / BigInt(10).power(18 - to.decimals)
        if isDebug {
          print("Rate from \(source) to \(dest): \(rate.string(decimals: to.decimals, minFractionDigits: 0, maxFractionDigits: 10))")
        }
      } else {
        throw CastError(actualValue: String.self, expectedType: BigInt.self)
      }
    }
  }

  init(source: String, dest: String, rate: Double, decimals: Int) {
    self.source = source
    self.dest = dest
    self.rate = BigInt(rate * pow(10.0, Double(decimals)))
    // 3% from rate
    self.minRate = self.rate * BigInt(97) / BigInt(100)
  }
}

extension KNRate {
  static func rateETH(from trackerRate: KNTrackerRate) -> KNRate {
    return KNRate(
      source: trackerRate.tokenSymbol,
      dest: "ETH",
      rate: trackerRate.tokenSymbol == "ETH" ? 1.0 : trackerRate.rateETHNow,
      decimals: 18
    )
  }

  static func rateUSD(from trackerRate: KNTrackerRate) -> KNRate {
    return KNRate(
      source: trackerRate.tokenSymbol,
      dest: "USD",
      rate: trackerRate.rateUSDNow,
      decimals: 18
    )
  }
}
