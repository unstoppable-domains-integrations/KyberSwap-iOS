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

  var isETH: Bool {
    return symbol == "ETH"
  }

  var isKNC: Bool {
    return symbol == "KNC"
  }

  var display: String {
    return "\(symbol) - \(name)"
  }

  static public func ==(lhs: KNToken, rhs: KNToken) -> Bool {
    return rhs.symbol == lhs.symbol && rhs.address == lhs.address
  }
}
