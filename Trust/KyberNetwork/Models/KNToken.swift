// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore

struct KNToken {

  let name: String
  let symbol: String
  let icon: String
  let address: String
  let decimal: Int
  let usdID: String

  init(dictionary: JSONDictionary) throws {
    name = try kn_cast(dictionary["name"])
    symbol = try kn_cast(dictionary["symbol"])
    icon = try kn_cast(dictionary["icon"])
    address = try kn_cast(dictionary["address"])
    decimal = try kn_cast(dictionary["decimal"])
    usdID = try kn_cast(dictionary["usd_id"])
  }

  init(
    name: String,
    symbol: String,
    icon: String = "",
    address: String,
    decimal: Int,
    usdID: String = ""
    ) {
    self.name = name
    self.symbol = symbol
    self.icon = icon
    self.address = address
    self.decimal = decimal
    self.usdID = usdID
  }

  var isETH: Bool {
    return symbol == "ETH"
  }

  var isKNC: Bool {
    return symbol == "KNC"
  }

  var display: String {
    return "\(symbol) - \(name)"
  }

  static public func ethToken() -> KNToken {
    return KNJSONLoaderUtil.shared.tokens.first(where: { $0.isETH })!
  }

  static public func kncToken() -> KNToken {
    return KNJSONLoaderUtil.shared.tokens.first(where: { $0.isKNC })!
  }

  static public func==(lhs: KNToken, rhs: KNToken) -> Bool {
    return rhs.symbol == lhs.symbol && rhs.address == lhs.address
  }

  //swiftlint:disable operator_whitespace
  static public func !=(lhs: KNToken, rhs: KNToken) -> Bool {
    return rhs.symbol != lhs.symbol || rhs.address != lhs.address
  }
}

extension KNToken {
  func toTokenObject() -> TokenObject {
    return TokenObject(
      contract: self.address,
      name: self.name,
      symbol: self.symbol,
      decimals: self.decimal,
      value: "0",
      isCustom: false,
      isDisabled: false
    )
  }

  static func from(tokenObject: TokenObject) -> KNToken {
    return KNToken(
      name: tokenObject.name,
      symbol: tokenObject.symbol,
      address: tokenObject.contract,
      decimal: tokenObject.decimals
    )
  }
}
