// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import RealmSwift
import BigInt
import TrustKeystore
import TrustCore

class TokenObject: Object {
    @objc dynamic var contract: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var symbol: String = ""
    @objc dynamic var decimals: Int = 0
    @objc dynamic var value: String = ""
    @objc dynamic var icon: String = ""
    @objc dynamic var isCustom: Bool = false
    @objc dynamic var isSupported: Bool = false
    @objc dynamic var isDisabled: Bool = false

    convenience init(
        contract: String = "",
        name: String = "",
        symbol: String = "",
        decimals: Int = 0,
        value: String,
        icon: String = "",
        isCustom: Bool = false,
        isSupported: Bool = false,
        isDisabled: Bool = false
    ) {
        self.init()
        self.contract = contract
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.value = value
        self.icon = icon
        self.isCustom = isCustom
        self.isSupported = isSupported
        self.isDisabled = isDisabled
    }

    // init from local json
    convenience init(localDict: JSONDictionary) {
      self.init()
      self.name = localDict["name"] as? String ?? ""
      self.symbol = localDict["symbol"] as? String ?? ""
      self.icon = localDict["icon"] as? String ?? self.symbol.lowercased()
      self.contract = localDict["address"] as? String ?? ""
      self.decimals = localDict["decimal"] as? Int ?? 0
      self.isSupported = true
    }

    // init from tracker api
    convenience init(trackerDict: JSONDictionary) {
      self.init()
      self.name = trackerDict["name"] as? String ?? ""
      self.symbol = trackerDict["symbol"] as? String ?? ""
      self.icon = (trackerDict["iconID"] as? String ?? "").lowercased()
      self.contract = trackerDict["contractAddress"] as? String ?? ""
      self.decimals = trackerDict["decimals"] as? Int ?? 0
      self.isSupported = true
    }

    var isETH: Bool {
      return self.symbol == "ETH" && self.name.lowercased() == "ethereum"
    }

    var isKNC: Bool {
      return self.symbol == "KNC" && self.name.replacingOccurrences(of: " ", with: "").lowercased() == "kybernetwork"
    }

    var display: String {
      return "\(self.symbol) - \(self.name)"
    }

    var address: Address {
        return Address(string: contract)!
    }

    var valueBigInt: BigInt {
        return BigInt(value) ?? BigInt()
    }

    override static func primaryKey() -> String? {
        return "contract"
    }

    override static func ignoredProperties() -> [String] {
        return ["type"]
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TokenObject else { return false }
        return object.contract == self.contract
    }

    var title: String {
        return name.isEmpty ? symbol : (name + " (" + symbol + ")")
    }

    var symbolAndNameID: String {
      return self.symbol + " " + self.name.replacingOccurrences(of: " ", with: "").lowercased()
    }

  /**
   Clone object to use in another realm
  */
  func clone() -> TokenObject {
    return TokenObject(
      contract: self.contract,
      name: self.name,
      symbol: self.symbol,
      decimals: self.decimals,
      value: self.value,
      icon: self.icon,
      isCustom: self.isCustom,
      isSupported: self.isSupported,
      isDisabled: self.isDisabled
    )
  }
}
