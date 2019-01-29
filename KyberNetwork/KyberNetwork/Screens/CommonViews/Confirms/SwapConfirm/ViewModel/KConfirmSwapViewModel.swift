// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KConfirmSwapViewModel {

  let transaction: KNDraftExchangeTransaction

  init(transaction: KNDraftExchangeTransaction) {
    self.transaction = transaction
  }

  var titleString: String {
    return "\(self.transaction.from.symbol) -> \(self.transaction.to.symbol)"
  }

  var leftAmountString: String {
    let amountString = self.transaction.amount.displayRate(decimals: transaction.from.decimals)
    return "\(amountString.prefix(12)) \(self.transaction.from.symbol)"
  }

  var rightAmountString: String {
    let receivedAmount = self.transaction.displayExpectedReceive(short: false)
    return "\(receivedAmount.prefix(12)) \(self.transaction.to.symbol)"
  }

  var displayEstimatedRate: String {
    let rateString = self.transaction.expectedRate.displayRate(decimals: transaction.to.decimals)
    return "1 \(self.transaction.from.symbol) = \(rateString) \(self.transaction.to.symbol)"
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
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "~ --- USD" }
    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
    let value: BigInt = usdRate * self.transactionFee / BigInt(EthereumUnit.ether.rawValue)
    let valueString: String = value.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }
}
