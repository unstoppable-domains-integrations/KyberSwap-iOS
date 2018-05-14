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
        rate = BigInt(rateDouble * Double(EthereumUnit.ether.rawValue))
        minRate = rate
        if isDebug { print("Rate from \(source) to USD: \(EtherNumberFormatter.full.string(from: rate))") }
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

  init(source: String, dest: String, rate: Double) {
    self.source = source
    self.dest = dest
    self.rate = BigInt(rate * Double(EthereumUnit.ether.rawValue))
    self.minRate = BigInt(rate * Double(EthereumUnit.ether.rawValue))
  }
}

extension KNRate {
  static func rateUSD(from coinTicker: KNCoinTicker) -> KNRate {
    return KNRate(
      source: coinTicker.symbol,
      dest: "USD",
      rate: coinTicker.priceUSD
    )
  }

  static func rate(from token: KNToken, toToken: KNToken) -> KNRate? {
    let coinTickers = KNCoinTickerStorage.shared.coinTickers
    if let fromCoinTicker = coinTickers.first(where: { $0.isData(for: token) }),
      let toCoinTicker = coinTickers.first(where: { $0.isData(for: toToken) }),
      toCoinTicker.priceUSD > 0 {
      let rate = fromCoinTicker.priceUSD / toCoinTicker.priceUSD
      return KNRate(
        source: token.symbol,
        dest: toToken.symbol,
        rate: rate
      )
    }
    return nil
  }

  static func rateETH(from coinTicker: KNCoinTicker) -> KNRate? {
    if let ethCoinTicker = KNCoinTickerStorage.shared.coinTickers.first(where: { $0.id == "ethereum" }), ethCoinTicker.priceUSD > 0 {
      let rateETH = coinTicker.priceUSD / ethCoinTicker.priceUSD
      return KNRate(
        source: coinTicker.symbol,
        dest: ethCoinTicker.symbol,
        rate: rateETH
      )
    }
    return nil
  }
}
