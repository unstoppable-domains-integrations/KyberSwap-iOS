// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNCoinTicker: Object {

  @objc dynamic var id: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var symbol: String = ""
  @objc dynamic var rank: Int = 0
  @objc dynamic var priceUSD: Double = 0
  @objc dynamic var priceBTC: Double = 0
  @objc dynamic var volumeUSD24h: Double = 0
  @objc dynamic var marketCapUSD: Double = 0
  @objc dynamic var availableSupply: Double = 0
  @objc dynamic var totalSupply: Double = 0
  @objc dynamic var maxSupply: Double = 0
  @objc dynamic var percentChange1h: String = "0"
  @objc dynamic var percentChange24h: String = "0"
  @objc dynamic var percentChange7d: String = "0"
  @objc dynamic var currency: String = "USD"
  @objc dynamic var priceCurrency: Double = 0
  @objc dynamic var volume24hCurrency: Double = 0
  @objc dynamic var marketCapCurrency: Double = 0
  @objc dynamic var lastUpdated: Date = Date()

  convenience init(dict: JSONDictionary, currency: String) throws {
    self.init()
    self.id = try kn_cast(dict["id"])
    self.name = try kn_cast(dict["name"])
    self.symbol = try kn_cast(dict["symbol"])
    self.rank = try {
      let rankString: String = try kn_cast(dict["rank"])
      return try kn_cast(rankString)
    }()
    self.priceUSD = try {
      let priceUSDString: String = try kn_cast(dict["price_usd"])
      return try kn_cast(priceUSDString)
    }()
    self.priceBTC = try {
      let priceBTCString: String = try kn_cast(dict["price_btc"])
      return try kn_cast(priceBTCString)
    }()
    self.volumeUSD24h = try {
      let volumeUSD24hString: String = try kn_cast(dict["24h_volume_usd"])
      return try kn_cast(volumeUSD24hString)
    }()
    self.marketCapUSD = try {
      let marketCapUSDString: String = try kn_cast(dict["market_cap_usd"])
      return try kn_cast(marketCapUSDString)
    }()
    self.availableSupply = try {
      let availableSupplyString: String = try kn_cast(dict["available_supply"])
      return try kn_cast(availableSupplyString)
    }()
    self.totalSupply = try {
      let totalSupplyString: String = try kn_cast(dict["total_supply"])
      return try kn_cast(totalSupplyString)
    }()
    self.maxSupply = try {
      let maxSupplyString: String = try kn_cast(dict["max_supply"])
      return try kn_cast(maxSupplyString)
    }()
    self.percentChange1h = try kn_cast(dict["percent_change_1h"])
    self.percentChange24h = try kn_cast(dict["percent_change_24h"])
    self.percentChange7d = try kn_cast(dict["percent_change_7d"])
    self.lastUpdated = try {
      let lastUpdatedString: String = try kn_cast(dict["last_updated"])
      let lastUpdatedDouble: Double = try kn_cast(lastUpdatedString)
      return Date(timeIntervalSince1970: lastUpdatedDouble)
    }()
    self.currency = currency
    self.priceCurrency = try {
      let priceCurrencyString: String = try kn_cast(dict["price_\(currency.lowercased())"])
      return try kn_cast(priceCurrencyString)
    }()
    self.volume24hCurrency = try {
      let volumeCurrency24hString: String = try kn_cast(dict["24h_volume_\(currency.lowercased())"])
      return try kn_cast(volumeCurrency24hString)
    }()
    self.marketCapCurrency = try {
      let marketCapCurrencyString: String = try kn_cast(dict["market_cap_\(currency.lowercased())"])
      return try kn_cast(marketCapCurrencyString)
    }()
  }

  override class func primaryKey() -> String? {
    return "id"
  }
}
