// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

public struct KNGasConfiguration {
  static let exchangeTokensGasLimitDefault = BigInt(660_000)
  static let transferTokenGasLimitDefault = BigInt(60_000)
  static let transferETHGasLimitDefault = BigInt(21_000)
  static let buytokenSaleByETHGasLimitDefault = BigInt(550_000)
  static let buyTokenSaleByTokenGasLimitDefault = BigInt(700_000)

  static let gasPriceDefault: BigInt = EtherNumberFormatter.full.number(from: "10", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMin: BigInt = EtherNumberFormatter.full.number(from: "5", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMax: BigInt = EtherNumberFormatter.full.number(from: "50", units: UnitConfiguration.gasPriceUnit)!
}
