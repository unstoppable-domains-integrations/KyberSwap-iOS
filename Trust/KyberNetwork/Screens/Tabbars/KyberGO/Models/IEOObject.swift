// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import BigInt

enum IEOObjectType: Int {
  case active = 0
  case upcoming = 1
  case past = 2
}

class IEOObject: Object {

  @objc dynamic var id: Int = -1
  @objc dynamic var contract: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var term: String = ""
  @objc dynamic var desc: String = ""
  @objc dynamic var icon: String = ""
  @objc dynamic var blackListNal = ""
  @objc dynamic var blackListCountries = ""
  // RealmSwift does not support type dictionary
  var customInfoFields: List<String> = List<String>()
  var customInfoValues: List<String> = List<String>()
  @objc dynamic var headline: String = ""
  @objc dynamic var subtitle: String = ""
  @objc dynamic var tagLine: String = ""
  @objc dynamic var standardRate: String = ""
  @objc dynamic var hardcapETH: Double = 0.0
  var bonusInfoFields: List<String> = List<String>()
  var bonusInfoValues: List<String> = List<String>()
  @objc dynamic var bannerShort: String = ""
  @objc dynamic var bannerLong: String = ""
  @objc dynamic var startDate: Date = Date()
  @objc dynamic var endDate: Date = Date()
  @objc dynamic var capLiftedDate: Date = Date()
  @objc dynamic var contributorCapETH: String = ""
  @objc dynamic var hardcap: String = ""
  @objc dynamic var raised: Double = 0.0
  @objc dynamic var rate: String = "0.0" // 1ETH = rate(symbol)
  @objc dynamic var tokenName: String = ""
  @objc dynamic var tokenAddr: String = ""
  @objc dynamic var tokenSymbol: String = ""
  @objc dynamic var tokenDecimals: Int = 0
  @objc dynamic var totalSupply: String = ""
  @objc dynamic var soldOut: Bool = false
  @objc dynamic var halted: Bool = false

  @objc dynamic var needsUpdateRate: Bool = true
  @objc dynamic var needsUpdateRaised: Bool = true

  convenience init(dict: JSONDictionary) {
    self.init()
    self.id = dict["id"] as? Int ?? -1
    self.contract = dict["contract_address"] as? String ?? ""
    self.name = dict["name"] as? String ?? ""
    self.term = dict["term"] as? String ?? ""
    self.icon = {
      guard let iconJson = dict["icon"] as? JSONDictionary else { return "" }
      return KNAppTracker.getKyberProfileBaseString() + (iconJson["url"] as? String ?? "")
    }()
    self.blackListNal = dict["blacklist_nationalities"] as? String ?? ""
    self.blackListCountries = dict["blacklist_country_of_residences"] as? String ?? ""
    self.desc = dict["description"] as? String ?? ""
    if let customInfo = dict["custom_info"] as? String, let objects = customInfo.jsonValue as? [JSONDictionary] {
      for id in 0..<objects.count {
        if let type = objects[id]["type"] as? String, let url = objects[id]["url"] as? String {
          self.customInfoFields.append(type)
          self.customInfoValues.append(url)
        }
      }
    }
    self.soldOut = dict["soldout"] as? Bool ?? false
    self.halted = false
    self.headline = dict["headline"] as? String ?? ""
    self.subtitle = dict["subtitle"] as? String ?? ""
    self.tagLine = dict["tagline"] as? String ?? ""
    self.standardRate = dict["standard_rate"] as? String ?? ""
    self.hardcapETH = dict["hardcap_eth"] as? Double ?? 0.0
    if let bonusInfo = dict["bonus_info"] as? String, let objects = bonusInfo.jsonValue as? [JSONDictionary] {
      for id in 0..<objects.count {
        if let value = objects[id]["value"] as? String, let date = objects[id]["date"] as? String {
          self.bonusInfoFields.append(value)
          self.bonusInfoValues.append(date)
        }
      }
    }
    self.bannerShort = {
      guard let json = dict["short_banner"] as? JSONDictionary else { return "" }
      return KNAppTracker.getKyberProfileBaseString() + (json["url"] as? String ?? "")
    }()
    self.bannerLong = {
      guard let json = dict["long_banner"] as? JSONDictionary else { return "" }
      return KNAppTracker.getKyberProfileBaseString() + (json["url"] as? String ?? "")
    }()
    guard let details = dict["details"] as? JSONDictionary else { return }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    self.startDate = {
      let time = details["start_time"] as? String ?? ""
      return dateFormatter.date(from: time) ?? Date()
    }()
    self.endDate = {
      let time = details["end_time"] as? String ?? ""
      return dateFormatter.date(from: time) ?? Date()
    }()
    self.capLiftedDate = {
      let time = details["cap_lifted_time"] as? String ?? ""
      return dateFormatter.date(from: time) ?? Date()
    }()
    self.contributorCapETH = details["contributor_cap_eth"] as? String ?? "0.0"
    self.hardcap = details["hardcap"] as? String ?? "0.0"
    self.tokenName = details["token_name"] as? String ?? ""
    self.tokenAddr = details["token_address"] as? String ?? ""
    self.tokenSymbol = details["token_symbol"] as? String ?? ""
    self.tokenDecimals = details["token_decimals"] as? Int ?? 0
    self.needsUpdateRate = true
    self.needsUpdateRaised = true
    if let value = Double(self.standardRate) {
      self.standardRate = BigInt(value * pow(10.0, Double(self.tokenDecimals))).string(decimals: self.tokenDecimals, minFractionDigits: 0, maxFractionDigits: 4)
    }
  }

  override static func primaryKey() -> String {
    return "id"
  }
}
extension IEOObject {
  var type: IEOObjectType {
    if self.endDate.timeIntervalSince(Date()) < 0 { return .past }
    if self.startDate.timeIntervalSince(Date()) > 0 { return .upcoming }
    return .active
  }

  var progress: Float {
    guard let cap = Double(hardcap), cap > 0 else { return 0.0 }
    return Float(raised / cap)
  }

  var isSoldOut: Bool {
    if self.soldOut { return true }
    return self.progress >= 0.99999
  }

  var getCurrentBonus: (Date?, String?) {
    let bonusDateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd'T'hh:mm"
      return formatter
    }()
    for id in 0..<self.bonusInfoFields.count {
      // field is bonus amount, value is end date
      let field = self.bonusInfoFields[id]
      let value = self.bonusInfoValues[id]
      if let date = bonusDateFormatter.date(from: value) {
        return (date, field)
      }
    }
    return (nil, nil)
  }

  var getAmountBonus: String? {
    return self.getCurrentBonus.1
  }

  var raisedText: String {
    return (BigInt(raised * pow(10.0, Double(self.tokenDecimals)))).string(
      decimals: self.tokenDecimals,
      minFractionDigits: 4,
      maxFractionDigits: 4
    )
  }

  var rateText: String {
    guard let bigInt = self.rate.fullBigInt(decimals: self.tokenDecimals) else { return "-.--" }
    return bigInt.string(
      decimals: self.tokenDecimals,
      minFractionDigits: 6,
      maxFractionDigits: 6
    )
  }

  var raisedPercent: String {
    let percent = Double(self.progress) * 100.0
    let display = percent.display(minFractionDigits: 2, maxFractionDigits: 2, minIntegerDigits: 2)
    return "\(display) %"
  }
}
