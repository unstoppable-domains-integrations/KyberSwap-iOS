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

  var titleString: String {
    return "\(NSLocalizedString("send", value: "Send", comment: "")) \(self.token.symbol)" }

  var contactName: String {
    let address = transaction.to?.description ?? NSLocalizedString("not.in.contact", value: "Not In Contact", comment: "")
    guard let contact = KNContactStorage.shared.contacts.first(where: { address.lowercased() == $0.address.lowercased() }) else { return NSLocalizedString("not.in.contact", value: "Not In Contact", comment: "") }
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

  var transactionFeeText: String { return "\(NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")): " }
  var transactionFeeETHString: String {
    let fee: BigInt? = {
      guard let gasPrice = self.transaction.gasPrice, let gasLimit = self.transaction.gasLimit else { return nil }
      return gasPrice * gasLimit
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "\(feeString) ETH"
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
      return fee.displayRate(decimals: 18)
    }()
    return "~ \(feeUSD) USD"
  }
}
