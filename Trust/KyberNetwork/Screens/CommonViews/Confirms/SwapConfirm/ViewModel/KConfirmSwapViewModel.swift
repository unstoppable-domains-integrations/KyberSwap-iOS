// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KConfirmSwapViewModel {

  let transaction: KNDraftExchangeTransaction

  init(transaction: KNDraftExchangeTransaction) {
    self.transaction = transaction
  }

  var titleString: String {
    return "\(self.transaction.from.symbol) to \(self.transaction.to.symbol)"
  }

  var leftAmountString: String {
    let amountString = self.transaction.amount.string(
      decimals: self.transaction.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: 4
    )
    return "\(amountString.prefix(12)) \(self.transaction.from.symbol)"
  }

  var rightAmountString: String {
    let receivedAmount = self.transaction.displayExpectedReceive(short: true)
    return "\(receivedAmount.prefix(12)) \(self.transaction.to.symbol)"
  }

  var displayEstimatedRate: String {
    let rateString = self.transaction.expectedRate.string(
      decimals: self.transaction.to.decimals,
      minFractionDigits: 0,
      maxFractionDigits: 6
    )
    return "1 \(self.transaction.from.symbol) = \(rateString.prefix(12)) \(self.transaction.to.symbol)"
  }

  var minRateString: String {
    let rate: String = {
      let minRate = self.transaction.minRate ?? BigInt(0)
      return minRate.string(
        decimals: self.transaction.to.decimals,
        minFractionDigits: 0,
        maxFractionDigits: 6
      )
    }()
    return "\(rate.prefix(8))"
  }

  var transactionFee: BigInt {
    let gasPrice: BigInt = self.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    let gasLimit: BigInt = self.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    return gasPrice * gasLimit
  }

  var feeETHString: String {
    return self.transactionFee.string(units: .ether, minFractionDigits: 6, maxFractionDigits: 6) + " ETH"
  }

  var feeUSDString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "~ --- USD" }
    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
    let value: BigInt = usdRate * self.transactionFee / BigInt(EthereumUnit.ether.rawValue)
    let valueString: String = value.string(units: .ether, minFractionDigits: 0, maxFractionDigits: 6)
    return "~ \(valueString.prefix(12)) USD"
  }
}
