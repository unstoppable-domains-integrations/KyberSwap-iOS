// Copyright SIX DAY LLC. All rights reserved.

import BigInt

extension String {

  func shortBigInt(decimals: Int) -> BigInt? {
    return EtherNumberFormatter.short.number(from: self, decimals: decimals)
  }

  func shortBigInt(units: EthereumUnit) -> BigInt? {
    return EtherNumberFormatter.short.number(from: self, units: units)
  }

  func fullBigInt(decimals: Int) -> BigInt? {
    return EtherNumberFormatter.full.number(from: self, decimals: decimals)
  }

  func fullBigInt(units: EthereumUnit) -> BigInt? {
    return EtherNumberFormatter.full.number(from: self, units: units)
  }
}
