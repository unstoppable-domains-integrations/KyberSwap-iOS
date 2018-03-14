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
      source = try kn_cast(dictionary["symbol"])
      dest = "USD"
      let rateString: String = try kn_cast(dictionary["price_usd"])
      if let rateDouble = Double(rateString) {
        rate = BigInt(rateDouble)
        minRate = rate
        if isDebug { print("Rate from \(source) to USD: \(EtherNumberFormatter.full.string(from: rate * BigInt(rateDouble * Double(EthereumUnit.ether.rawValue))))") }
      } else {
        throw CastError(actualValue: String.self, expectedType: Double.self)
      }
    } else {
      source = try kn_cast(dictionary["source"])
      dest =  try kn_cast(dictionary["dest"])
      let rateString: String = try kn_cast(dictionary["rate"])
      let minRateString: String = try kn_cast(dictionary["minRate"])
      if let rateDouble = Double(rateString), let minRateDouble = Double(minRateString) {
        rate = BigInt(rateDouble)
        minRate = BigInt(minRateDouble)
        if isDebug { print("Rate from \(source) to \(dest): \(EtherNumberFormatter.full.string(from: rate))") }
      } else {
        throw CastError(actualValue: String.self, expectedType: BigInt.self)
      }
    }
  }

  var displayRate: String {
    return EtherNumberFormatter.short.string(from: rate)
  }

  var displayMinRate: String {
    return EtherNumberFormatter.full.string(from: minRate)
  }
}
