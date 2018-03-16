// Copyright SIX DAY LLC. All rights reserved.

import BigInt

extension String {

  func removeGroupSeparator() -> String {
    return self.replacingOccurrences(of: EtherNumberFormatter.short.groupingSeparator, with: "")
  }

  func shortBigInt(decimals: Int) -> BigInt? {
    return EtherNumberFormatter.short.number(
      from: self.removeGroupSeparator(),
      decimals: decimals
    )
  }

  func shortBigInt(units: EthereumUnit) -> BigInt? {
    return EtherNumberFormatter.short.number(
      from: self.removeGroupSeparator(),
      units: units
    )
  }

  func fullBigInt(decimals: Int) -> BigInt? {
    return EtherNumberFormatter.full.number(
      from: self.removeGroupSeparator(),
      decimals: decimals
    )
  }

  func fullBigInt(units: EthereumUnit) -> BigInt? {
    return EtherNumberFormatter.full.number(
      from: self.removeGroupSeparator(),
      units: units
    )
  }
}
