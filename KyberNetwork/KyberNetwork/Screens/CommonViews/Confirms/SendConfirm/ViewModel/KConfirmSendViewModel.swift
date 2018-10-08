// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import JdenticonSwift

struct KConfirmSendViewModel {

  let transaction: UnconfirmedTransaction

  init(transaction: UnconfirmedTransaction) {
    self.transaction = transaction
  }

  var token: TokenObject { return transaction.transferType.tokenObject() }

  var addressToIcon: UIImage? {
    guard let data = self.transaction.to?.data else { return nil }
    return UIImage.generateImage(with: 75, hash: data)
  }

  var titleString: String { return "Send \(self.token.symbol)" }

  var contactName: String {
    let address = transaction.to?.description ?? "Not In Contact"
    guard let contact = KNContactStorage.shared.get(forPrimaryKey: address.lowercased()) else { return "Not In Contact" }
    return contact.name
  }

  var address: String {
    let address = transaction.to?.description ?? ""
    return "\(address.prefix(20))...\(address.suffix(8))"
  }

  var totalAmountString: String {
    let string = self.transaction.value.string(
      decimals: self.token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.token.decimals, 6)
    )
    return "\(string.prefix(12)) \(self.token.symbol)"
  }

  var usdValueString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else { return "" }
    let displayString: String = {
      let valueUSD = KNRate.rateUSD(from: trackerRate).rate * self.transaction.value / BigInt(10).power(self.token.decimals)
      return valueUSD.string(
        units: EthereumUnit.ether,
        minFractionDigits: 0,
        maxFractionDigits: 4
      )
    }()
    return "~ \(displayString) USD"
  }

  var transactionFeeText: String { return "Transaction Fee: " }
  var transactionFeeETHString: String {
    let fee: BigInt? = {
      guard let gasPrice = self.transaction.gasPrice, let gasLimit = self.transaction.gasLimit else { return nil }
      return gasPrice * gasLimit
    }()
    let feeString: String = fee?.string(
      units: EthereumUnit.ether,
      minFractionDigits: 0,
      maxFractionDigits: 9
    ) ?? ""
    return "\(feeString.prefix(12)) ETH"
  }

  var transactionFeeUSDString: String {
    let fee: BigInt? = {
      guard let gasPrice = self.transaction.gasPrice, let gasLimit = self.transaction.gasLimit else { return nil }
      return gasPrice * gasLimit
    }()
    guard let feeBigInt = fee else { return "" }
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
    let feeUSD: String = {
      let fee = feeBigInt * trackerRate.rateUSDBigInt / BigInt(EthereumUnit.ether.rawValue)
      return fee.string(units: .ether, minFractionDigits: 0, maxFractionDigits: 4)
    }()
    return "~ \(feeUSD) USD"
  }
}
