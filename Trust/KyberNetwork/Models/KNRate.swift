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
      dest =  dictionary["dest"] as? String ?? ""
      let rateString: String = dictionary["rate"] as? String ?? ""
      let minRateString: String = dictionary["minRate"] as? String ?? ""
      if let rateDouble = Double(rateString), let minRateDouble = Double(minRateString) {
        rate = BigInt(rateDouble)
        minRate = BigInt(minRateDouble)
        if isDebug { print("Rate from \(source) to \(dest): \(EtherNumberFormatter.full.string(from: rate))") }
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
