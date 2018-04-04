// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt

struct KNDraftExchangeTransaction {
  let from: KNToken
  let to: KNToken
  let amount: BigInt
  let maxDestAmount: BigInt
  let expectedRate: BigInt
  let minRate: BigInt?
  let gasPrice: BigInt?
  let gasLimit: BigInt?
}

extension KNDraftExchangeTransaction {
  func displayAmount(short: Bool = true) -> String {
    return short ? amount.shortString(decimals: from.decimal) : amount.fullString(decimals: from.decimal)
  }

  var expectedReceive: BigInt {
    return amount * expectedRate / BigInt(10).power(to.decimal)
  }

  func displayExpectedReceive(short: Bool = true) -> String {
    return short ? expectedReceive.shortString(decimals: to.decimal) : expectedReceive.fullString(decimals: to.decimal)
  }

  func displayExpectedRate(short: Bool = true) -> String {
    return short ? expectedRate.shortString(decimals: to.decimal) : expectedRate.fullString(decimals: to.decimal)
  }

  func displayMinRate(short: Bool = true) -> String? {
    return short ? minRate?.shortString(decimals: to.decimal) : minRate?.fullString(decimals: to.decimal)
  }

  var displayGasPrice: String? {
    return gasPrice?.shortString(units: UnitConfiguration.gasPriceUnit)
  }

  var fee: BigInt {
    return (gasPrice ?? BigInt(0)) * (gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault)
  }

  func displayFeeString(short: Bool = true) -> String {
    return short ? fee.shortString(units: UnitConfiguration.gasFeeUnit) : fee.fullString(units: UnitConfiguration.gasFeeUnit)
  }

  var usdValueStringForFee: String {
    let eth = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.isETH })!
    let rate = KNRateCoordinator.shared.usdRate(for: eth)?.rate ?? BigInt(0)
    return (rate * fee / BigInt(EthereumUnit.ether.rawValue)).shortString(units: .ether)
  }

  var usdRateForFromToken: KNRate? {
    return KNRateCoordinator.shared.usdRate(for: from)
  }

  var usdValueStringForFromToken: String {
    let rate = usdRateForFromToken?.rate ?? BigInt(0)
    return (rate * amount / BigInt(EthereumUnit.ether.rawValue)).shortString(units: .ether)
  }

  var usdRateForToToken: KNRate? {
    return KNRateCoordinator.shared.usdRate(for: to)
  }
}

extension KNDraftExchangeTransaction {

  func copy(expectedRate: BigInt, gasLimit: BigInt? = nil) -> KNDraftExchangeTransaction {
    return KNDraftExchangeTransaction(
      from: self.from,
      to: self.to,
      amount: self.amount,
      maxDestAmount: self.maxDestAmount,
      expectedRate: expectedRate,
      minRate: self.minRate,
      gasPrice: self.gasPrice,
      gasLimit: gasLimit ?? self.gasLimit
    )
  }

  func toTransaction(hash: String, fromAddr: Address, toAddr: Address, nounce: Int) -> Transaction {
    // temporary: local object contains from and to tokens + expected rate
    let expectedAmount: String = {
      return (self.amount * self.expectedRate / BigInt(10).power(self.to.decimal)).fullString(decimals: self.to.decimal)
    }()
    let localObject = LocalizedOperationObject(
      from: self.from.address,
      to: self.to.address,
      contract: nil,
      type: "exchange",
      value: expectedAmount,
      symbol: nil,
      name: nil,
      decimals: self.to.decimal
    )
    return Transaction(
      id: hash,
      blockNumber: 0,
      from: fromAddr.description,
      to: toAddr.description,
      value: self.amount.fullString(decimals: self.from.decimal),
      gas: self.gasLimit?.fullString(units: UnitConfiguration.gasFeeUnit) ?? "",
      gasPrice: self.gasPrice?.fullString(units: UnitConfiguration.gasPriceUnit) ?? "",
      gasUsed: self.gasLimit?.fullString(units: UnitConfiguration.gasFeeUnit) ?? "",
      nonce: "\(nounce)",
      date: Date(),
      localizedOperations: [localObject],
      state: .pending
    )
  }
}
