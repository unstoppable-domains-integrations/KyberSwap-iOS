// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore

class KNSendTokenViewModel: NSObject {

  fileprivate let gasPrices: [BigInt] = [
    KNGasConfiguration.gasPriceMin,
    KNGasConfiguration.gasPriceDefault,
    KNGasConfiguration.gasPriceMax,
  ]

  fileprivate(set) var from: TokenObject
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amount: String = ""
  fileprivate(set) var gasPrice: BigInt = KNGasConfiguration.gasPriceMax
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault

  fileprivate var addressString: String? = ""

  var amountBigInt: BigInt {
    return amount.shortBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var address: Address? {
    guard let addr = self.addressString else { return nil }
    return Address(string: addr)
  }

  init(from: TokenObject, balance: Balance?) {
    self.from = from
    self.balance = balance
  }

  var navTitle: String {
    return "Send \(self.from.symbol)" // "Send Token"
  }

  var displayToken: String {
    return self.from.symbol
  }

  var displayBalance: String {
    guard let bal = self.balance else { return "Balance: -- \(self.from.symbol)" }
    return "Balance: " + bal.value.shortString(decimals: self.from.decimals, maxFractionDigits: 6) + " \(self.from.symbol)"
  }

  var tokenIconName: String { return self.from.icon }

  var displayGasPrice: String {
    let val = self.gasPrice.shortString(units: UnitConfiguration.gasPriceUnit, maxFractionDigits: 1)
    return "\(val) gwei"
  }

  var placeHolderEnterAddress: String {
    return "Enter an address or scan its QR code".toBeLocalised()
  }

  var displayAddress: String? {
    //TODO: display address or contact name
    return self.addressString
  }

  var isAmountValid: Bool {
    let balanceVal = balance?.value ?? BigInt(0)
    return amountBigInt >= 0 && amountBigInt <= balanceVal
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
  }

  func updateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, amount: BigInt) {
    if self.from == from, self.amountBigInt == amount { self.gasLimit = gasLimit }
  }

  func updateAddress(_ address: String) {
    self.addressString = address
  }
}
