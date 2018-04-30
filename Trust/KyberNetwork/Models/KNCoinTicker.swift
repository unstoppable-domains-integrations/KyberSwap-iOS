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

  convenience init(dict: JSONDictionary, currency: String) {
    self.init()
    self.id = dict["id"] as? String ?? ""
    self.name = dict["name"] as? String ?? ""
    self.symbol = dict["symbol"] as? String ?? ""
    self.rank = {
      let rankString: String = dict["rank"] as? String ?? ""
      return Int(rankString) ?? 0
    }()
    self.priceUSD = {
      let priceUSDString: String = dict["price_usd"] as? String ?? ""
      return Double(priceUSDString) ?? 0
    }()
    self.priceBTC = {
      let priceBTCString: String = dict["price_btc"] as? String ?? ""
      return Double(priceBTCString) ?? 0
    }()
    self.volumeUSD24h = {
      let volumeUSD24hString: String = dict["24h_volume_usd"] as? String ?? ""
      return Double(volumeUSD24hString) ?? 0
    }()
    self.marketCapUSD = {
      let marketCapUSDString: String = dict["market_cap_usd"] as? String ?? ""
      return Double(marketCapUSDString) ?? 0
    }()
    self.availableSupply = {
      let availableSupplyString: String = dict["available_supply"] as? String ?? ""
      return Double(availableSupplyString) ?? 0
    }()
    self.totalSupply = {
      let totalSupplyString: String = dict["total_supply"] as? String ?? ""
      return Double(totalSupplyString) ?? 0
    }()
    self.maxSupply = {
      let maxSupplyString: String = dict["max_supply"] as? String ?? ""
      return Double(maxSupplyString) ?? 0
    }()
    self.percentChange1h = dict["percent_change_1h"] as? String ?? ""
    self.percentChange24h = dict["percent_change_24h"] as? String ?? ""
    self.percentChange7d = dict["percent_change_7d"] as? String ?? ""
    self.lastUpdated = {
      let lastUpdatedString: String = dict["last_updated"] as? String ?? ""
      let lastUpdatedDouble: Double = Double(lastUpdatedString) ?? 0
      return Date(timeIntervalSince1970: lastUpdatedDouble)
    }()
    self.currency = currency
    self.priceCurrency = {
      let priceCurrencyString: String = dict["price_\(currency.lowercased())"] as? String ?? ""
      return Double(priceCurrencyString) ?? 0
    }()
    self.volume24hCurrency = {
      let volumeCurrency24hString: String = dict["24h_volume_\(currency.lowercased())"] as? String ?? ""
      return Double(volumeCurrency24hString) ?? 0
    }()
    self.marketCapCurrency = {
      let marketCapCurrencyString: String = dict["market_cap_\(currency.lowercased())"] as? String ?? ""
      return Double(marketCapCurrencyString) ?? 0
    }()
  }

  override class func primaryKey() -> String? {
    return "id"
  }
}
