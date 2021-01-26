// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KConfirmSwapViewModel {

  let transaction: KNDraftExchangeTransaction
  let ethBalance: BigInt
  let signTransaction: SignTransaction
  let hasRateWarning: Bool
  let platform: String

  init(transaction: KNDraftExchangeTransaction, ethBalance: BigInt, signTransaction: SignTransaction, hasRateWarning: Bool, platform: String) {
    self.transaction = transaction
    self.ethBalance = ethBalance
    self.signTransaction = signTransaction
    self.hasRateWarning = hasRateWarning
    self.platform = platform
  }

  var titleString: String {
    return "\(self.transaction.from.symbol) ➞ \(self.transaction.to.symbol)"
  }

  var leftAmountString: String {
    let amountString = self.transaction.amount.displayRate(decimals: transaction.from.decimals)
    return "\(amountString.prefix(15)) \(self.transaction.from.symbol)"
  }

  var equivalentUSDAmount: BigInt? {
    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.transaction.to) {
      let expectedReceive = self.transaction.expectedReceive
      return usdRate.rate * expectedReceive / BigInt(10).power(self.transaction.to.decimals)
    }
    return nil
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  var rightAmountString: String {
    let receivedAmount = self.transaction.displayExpectedReceive(short: false)
    return "\(receivedAmount.prefix(15)) \(self.transaction.to.symbol)"
  }

  var displayEstimatedRate: String {
    let rateString = self.transaction.expectedRate.displayRate(decimals: transaction.to.decimals)
    return "1 \(self.transaction.from.symbol) = \(rateString) \(self.transaction.to.symbol)"
  }

  var warningMinAcceptableRateMessage: String? {
    guard let minRate = self.transaction.minRate, minRate >= self.transaction.expectedRate else { return nil }
    // min rate is zero
    return "Your configured minimal rate is higher than what is recommended by KyberNetwork. Your swap has high chance to fail.".toBeLocalised()
  }

  var minRateString: String {
    let minRate = self.transaction.minRate ?? BigInt(0)
    return minRate.displayRate(decimals: self.transaction.to.decimals)
  }

  var transactionFee: BigInt {
    let gasPrice: BigInt = self.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    let gasLimit: BigInt = self.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    return gasPrice * gasLimit
  }

  var feeETHString: String {
    let string: String = self.transactionFee.displayRate(decimals: 18)
    return "\(string) ETH"
  }

  var feeUSDString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
    let value: BigInt = usdRate * self.transactionFee / BigInt(EthereumUnit.ether.rawValue)
    let valueString: String = value.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var warningETHBalanceShown: Bool {
    if !self.transaction.from.isETH { return false }
    let totalAmount = self.transactionFee + self.transaction.amount
    return self.ethBalance - totalAmount <= BigInt(0.01 * pow(10.0, 18.0))
  }

  var transactionGasPriceString: String {
    let gasPrice: BigInt = self.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    let gasLimit: BigInt = self.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    let gasPriceText = gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }

  var hint: String {
    return self.transaction.hint ?? ""
  }
  
  var reverseRoutingText: String {
    return String(format: "Your transaction will be routed to %@ for better rate.".toBeLocalised(), self.platform.capitalized)
  }
}
