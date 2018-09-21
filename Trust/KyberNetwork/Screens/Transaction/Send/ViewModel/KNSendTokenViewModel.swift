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

  let defaultTokenIconImg = UIImage(named: "default_token")

  fileprivate(set) var from: TokenObject
  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amount: String = ""
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .fast
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault

  fileprivate(set) var addressString: String = ""

  var allTokenBalanceString: String {
    let string = self.balance?.value.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 9)
      ) ?? ""
    return "\(string.prefix(12))"
  }

  var amountBigInt: BigInt {
    return amount.shortBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var amountTextColor: UIColor {
    return isAmountValid ? UIColor.Kyber.lightSeaGreen : UIColor.red
  }

  var address: Address? {
    return Address(string: self.addressString)
  }

  init(from: TokenObject, balances: [String: Balance]) {
    self.from = from
    self.balances = balances
    self.balance = balances[from.contract]
  }

  var navTitle: String {
    return "Send \(self.from.symbol)" // "Send Token"
  }

  var tokenButtonAttributedText: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 22),
      NSAttributedStringKey.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
    ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 13),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.gray,
    ]
    attributedString.append(NSAttributedString(string: self.from.symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(self.from.name)", attributes: nameAttributes))
    return attributedString
  }

  var balanceText: String {
    return "\(self.from.symbol) Balance".uppercased()
  }

  var displayBalance: String {
    guard let bal = self.balance else { return "---" }
    let string = bal.value.string(decimals: self.from.decimals, minFractionDigits: 0, maxFractionDigits: 9)
    return "\(string.prefix(12))"
  }

  var placeHolderEnterAddress: String {
    return "Recipient address".toBeLocalised()
  }

  var displayAddress: String? {
    if self.address == nil { return self.addressString }
    if let contact = KNContactStorage.shared.get(forPrimaryKey: self.addressString.lowercased()) {
      return "\(contact.name) - \(self.addressString)"
    }
    return self.addressString
  }

  var newContactTitle: String {
    if KNContactStorage.shared.get(forPrimaryKey: self.addressString.lowercased()) != nil {
      return "Edit Contact".toBeLocalised()
    }
    return "Add Contact".toBeLocalised()
  }

  var isAmountTooSmall: Bool {
    return self.amountBigInt <= BigInt(0)
  }

  var isAmountTooBig: Bool {
    let balanceVal = balance?.value ?? BigInt(0)
    return amountBigInt > balanceVal
  }

  var isAmountValid: Bool {
    return !isAmountTooBig && !isAmountTooSmall
  }

  var isAddressValid: Bool {
    return self.address != nil
  }

  var isHavingEnoughETHForFee: Bool {
    let fee = self.gasPrice * self.gasLimit
    let eth = KNSupportedTokenStorage.shared.ethToken
    let ethBal = self.balances[eth.contract]?.value ?? BigInt(0)
    return ethBal >= fee
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

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      self.balance = bal
    }
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
