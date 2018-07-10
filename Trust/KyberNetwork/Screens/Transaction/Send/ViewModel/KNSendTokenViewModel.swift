// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore

class KNSendTokenViewModel: NSObject {

  fileprivate let gasPrices: [BigInt] = [
    KNGasConfiguration.gasPriceMin,
    KNGasConfiguration.gasPriceDefault,
    KNGasConfiguration.gasPriceMax,
  ]

  fileprivate(set) var from: TokenObject
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amount: String = ""
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .fast
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault

  fileprivate(set) var addressString: String = ""

  var allTokenBalanceString: String {
    return self.balance?.value.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: self.from.decimals
    ) ?? ""
  }

  var amountBigInt: BigInt {
    return amount.shortBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var amountTextColor: UIColor {
    return isAmountValid ? UIColor(hex: "31cb9e") : UIColor.red
  }

  var address: Address? {
    return Address(string: self.addressString)
  }

  init(from: TokenObject, balance: Balance?) {
    self.from = from
    self.balance = balance
  }

  var navTitle: String {
    return "Send \(self.from.symbol)" // "Send Token"
  }

  var tokenButtonAttributedText: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 22)!,
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
    ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont(name: "SFProText-Regular", size: 13)!,
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
    ]
    attributedString.append(NSAttributedString(string: self.from.symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(self.from.name)", attributes: nameAttributes))
    return attributedString
  }

  var balanceText: String {
    return "\(self.from.symbol) Balance"
  }

  var displayBalance: String {
    guard let bal = self.balance else { return "---" }
    return bal.value.shortString(decimals: self.from.decimals, maxFractionDigits: 6)
  }

  var tokenIconName: String { return self.from.icon }

  var placeHolderEnterAddress: String {
    return "Enter address or scan QR code".toBeLocalised()
  }

  var displayAddress: String? {
    if self.address == nil { return self.addressString }
    let displayedString = "\(self.addressString.prefix(8))....\(self.addressString.suffix(6))"
    if let contact = KNContactStorage.shared.get(forPrimaryKey: self.addressString.lowercased()) {
      return "\(contact.name) - \(displayedString)"
    }
    return displayedString
  }

  var newContactTitle: String {
    if KNContactStorage.shared.get(forPrimaryKey: self.addressString.lowercased()) != nil {
      return "Edit Contact".toBeLocalised()
    }
    return "Add Contact".toBeLocalised()
  }

  var isAmountValid: Bool {
    let balanceVal = balance?.value ?? BigInt(0)
    return amountBigInt > 0 && amountBigInt <= balanceVal
  }

  var isAddressValid: Bool {
    return self.address != nil
  }

  var unconfirmTransaction: UnconfirmedTransaction {
    let transferType: TransferType = {
      if self.from.isETH {
        return TransferType.ether(destination: self.address)
      }
      return TransferType.token(self.from)
    }()
    return UnconfirmedTransaction(
      transferType: transferType,
      value: self.amountBigInt,
      to: self.address,
      data: nil,
      gasLimit: self.gasLimit,
      gasPrice: self.gasPrice,
      nonce: .none
    )
  }

  // MARK: Update
  func updateSendToken(from token: TokenObject, balance: Balance?) {
    self.from = token
    self.balance = balance
    self.amount = ""
    self.gasLimit = self.from.isETH ? KNGasConfiguration.transferETHGasLimitDefault : KNGasConfiguration.transferTokenGasLimitDefault
  }

  func updateBalance(_ balance: Balance?) {
    self.balance = balance
  }

  func updateAmount(_ amount: String) {
    self.amount = amount
  }

  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
    self.selectedGasPriceType = .custom
  }

  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    default: return
    }
  }

  func updateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, amount: BigInt) {
    if self.from == from, self.amountBigInt == amount { self.gasLimit = gasLimit }
  }

  func updateAddress(_ address: String) {
    self.addressString = address
  }
}
