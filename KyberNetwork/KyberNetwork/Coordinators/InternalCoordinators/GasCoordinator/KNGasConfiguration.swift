// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

public struct KNGasConfiguration {
  static let digixGasLimitDefault = BigInt(770_000)
  static let exchangeTokensGasLimitDefault = BigInt(660_000)
  static let exchangeETHTokenGasLimitDefault = BigInt(350_000)
  static let approveTokenGasLimitDefault = BigInt(100_000)
  static let transferTokenGasLimitDefault = BigInt(60_000)
  static let transferETHGasLimitDefault = BigInt(21_000)
  static let buytokenSaleByETHGasLimitDefault = BigInt(550_000)
  static let buyTokenSaleByTokenGasLimitDefault = BigInt(700_000)

  static let gasPriceDefault: BigInt = EtherNumberFormatter.full.number(from: "10", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMin: BigInt = EtherNumberFormatter.full.number(from: "5", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMax: BigInt = EtherNumberFormatter.full.number(from: "50", units: UnitConfiguration.gasPriceUnit)!

  static func calculateDefaultGasLimit(from: TokenObject, to: TokenObject) -> BigInt {
    if from == to {
      // normal transfer
      if from.isETH { return transferETHGasLimitDefault }
      return transferTokenGasLimitDefault
    }
    // swapping
    if from.isDGX {
      // swapping digix to eth or token
      return to.isETH ? digixGasLimitDefault : digixGasLimitDefault + exchangeETHTokenGasLimitDefault
    }
    if to.isDGX {
      return from.isETH ? digixGasLimitDefault : digixGasLimitDefault + exchangeETHTokenGasLimitDefault
    }
    // swap ETH <-> token or token <-> token
    return (from.isETH || to.isETH) ? exchangeETHTokenGasLimitDefault : exchangeTokensGasLimitDefault
  }
}
