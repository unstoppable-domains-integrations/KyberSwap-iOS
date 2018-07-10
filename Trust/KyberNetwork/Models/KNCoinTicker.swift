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
    self.id = {
      let idInt: Int = dict["id"] as? Int ?? 0
      return "\(idInt)"
    }()
    self.name = dict["name"] as? String ?? ""
    self.symbol = dict["symbol"] as? String ?? ""
    self.rank = dict["rank"] as? Int ?? 0
    self.priceBTC = {
      let priceBTCString: String = dict["price_btc"] as? String ?? ""
      return Double(priceBTCString) ?? 0
    }()
    self.lastUpdated = {
      let lastUpdated: Double = dict["last_updated"] as? Double ?? 0.0
      return Date(timeIntervalSince1970: lastUpdated)
    }()
    self.availableSupply = dict["available_supply"] as? Double ?? 0.0
    self.totalSupply = dict["total_supply"] as? Double ?? 0.0
    self.maxSupply = dict["max_supply"] as? Double ?? 0.0

    guard let quotes = dict["quotes"] as? JSONDictionary else { return }
    guard let usdDict = quotes["USD"] as? JSONDictionary else { return }
    self.priceUSD = usdDict["price"] as? Double ?? 0.0
    self.percentChange1h = {
      let value = usdDict["percent_change_1h"] as? Double ?? 0.0
      return "\(value)"
    }()
    self.percentChange24h = {
      let value = usdDict["percent_change_24h"] as? Double ?? 0.0
      return "\(value)"
    }()
    self.percentChange7d = {
      let value = usdDict["percent_change_7d"] as? Double ?? 0.0
      return "\(value)"
    }()
    self.volumeUSD24h = usdDict["volume_24h"] as? Double ?? 0.0
    self.marketCapUSD = usdDict["market_cap"] as? Double ?? 0.0
    self.currency = currency
    guard let currencyDict = quotes[currency.uppercased()] as? JSONDictionary else { return }
    self.priceCurrency = currencyDict["price"] as? Double ?? 0.0
    self.volume24hCurrency = currencyDict["volume_24h"] as? Double ?? 0.0
    self.marketCapCurrency = currencyDict["market_cap"] as? Double ?? 0.0
  }

  override class func primaryKey() -> String? {
    return "id"
  }
}

extension KNCoinTicker {
  func isData(for token: TokenObject) -> Bool {
    return self.symbol == token.symbol
    && self.name.replacingOccurrences(of: " ", with: "").lowercased() == token.name.replacingOccurrences(of: " ", with: "").lowercased()
  }
}
