// Copyright SIX DAY LLC. All rights reserved.

import BigInt

extension String {

  func removeGroupSeparator() -> String {
    return self.replacingOccurrences(of: EtherNumberFormatter.short.groupingSeparator, with: "")
  }

  func shortBigInt(decimals: Int) -> BigInt? {
    if let double = Double(self.removeGroupSeparator()) {
      return BigInt(double * pow(10.0, Double(decimals)))
    }
    return EtherNumberFormatter.short.number(
      from: self.removeGroupSeparator(),
      decimals: decimals
    )
  }

  func shortBigInt(units: EthereumUnit) -> BigInt? {
    if let double = Double(self.removeGroupSeparator()) {
      return BigInt(double * Double(units.rawValue))
    }
    return EtherNumberFormatter.short.number(
      from: self.removeGroupSeparator(),
      units: units
    )
  }

  func fullBigInt(decimals: Int) -> BigInt? {
    if let double = Double(self.removeGroupSeparator()) {
      return BigInt(double * pow(10.0, Double(decimals)))
    }
    return EtherNumberFormatter.full.number(
      from: self.removeGroupSeparator(),
      decimals: decimals
    )
  }

  func fullBigInt(units: EthereumUnit) -> BigInt? {
    if let double = Double(self.removeGroupSeparator()) {
      return BigInt(double * Double(units.rawValue))
    }
    return EtherNumberFormatter.full.number(
      from: self.removeGroupSeparator(),
      units: units
    )
  }
}
