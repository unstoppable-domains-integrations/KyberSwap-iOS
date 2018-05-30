// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNExchangeTabViewModel {

  var wallet: Wallet
  var walletObject: KNWalletObject
  var from: TokenObject
  var to: TokenObject
  var supportedTokens: [TokenObject] = []

  var balances: [String: Balance] = [:]
  var balance: Balance?
  var amount: String = ""
  var estRate: BigInt?
  var slippageRate: BigInt?
  var slippagePercentage: Double?
  var gasPrice: BigInt = KNGasConfiguration.gasPriceMax
  var estimateGasLimit: BigInt = KNGasConfiguration.exchangeTokensGasLimitDefault

  init(wallet: Wallet,
       from: TokenObject,
       to: TokenObject,
       supportedTokens: [TokenObject]
    ) {
    self.wallet = wallet
    let addr = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr) ?? KNWalletObject(address: addr)
    self.from = from
    self.to = to
    self.supportedTokens = supportedTokens
  }

  var amountBigInt: BigInt {
    return self.amount.fullBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var fromTokenBtnTitle: String {
    return self.from.symbol
  }

  var fromTokenIconName: String {
    return self.from.icon
  }

  var toTokenBtnTitle: String {
    return self.to.symbol
  }

  var toTokenIconName: String {
    return self.to.icon
  }

  var balanceText: String {
    let bal: BigInt = self.balance?.value ?? BigInt(0)
    return "Balance: \(bal.shortString(decimals: self.from.decimals))"
  }

  var exchangeRateText: String {
    let rateString: String = self.estRate?.shortString(decimals: self.to.decimals) ?? "---"
    return "1 \(self.from.symbol) = \(rateString) \(self.to.symbol)"
  }

  var expectedReceivedAmountText: String {
    guard let rate = self.estRate else {
      return "--- \(self.to.symbol)"
    }
    let expectedAmount: BigInt = {
      let amount = self.amount.fullBigInt(decimals: self.from.decimals) ?? BigInt(0)
      return rate * amount / BigInt(10).power(self.to.decimals)
    }()
    return "\(expectedAmount.shortString(decimals: self.to.decimals)) \(self.to.symbol)"
  }

  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }

  var realSlippageRate: BigInt? {
    let slippageRate: BigInt? = {
      guard let percent = self.slippagePercentage, let estRate = self.estRate else {
        return self.slippageRate
      }
      return estRate * BigInt(100.0 - percent) / BigInt(100)
    }()
    return slippageRate
  }

  var slippageRateText: String {
    if let slippagePercent = self.slippagePercentage { return "\(slippagePercent) %" }
    if let rate = self.estRate, let slippage = self.slippageRate, !rate.isZero {
      let percentage = (rate - slippage) * BigInt(100) / rate
      return "\(percentage.shortString(decimals: 0)) %"
    }
    return "-- %"
  }

  // MARK: Verify data
  // Amount should > 0 and <= balance
  var isAmountValid: Bool {
    if self.amountBigInt <= BigInt(0) { return false }
    if self.amountBigInt > self.balance?.value ?? BigInt(0) { return false }
    return true
  }

  // rate should not be nil and greater than zero
  var isRateValid: Bool {
    if self.estRate == nil || self.realSlippageRate == nil { return false }
    if self.estRate?.isZero == true || self.realSlippageRate?.isZero == true { return false }
    return true
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    self.amount = ""
    self.balances = [:]
    self.balance = nil
    self.estRate = nil
    self.slippageRate = nil
    self.slippagePercentage = nil
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
  }
  func swapTokens() {
    swap(&self.from, &self.to)
    self.amount = ""
    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
    self.balance = self.balances[self.from.contract]
  }

  func updateSelectedToken(_ token: TokenObject, isSource: Bool) {
    if isSource {
      self.from = token
    } else {
      self.to = token
    }
    if !isSource { self.amount = "" }
    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
    self.balance = self.balances[self.from.contract]
  }

  func updateAmount(_ amount: String) {
    self.amount = amount
  }

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      self.balance = bal
    }
  }

  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
  }

  func updateSlippagePercent(_ percent: Double) {
    self.slippagePercentage = percent
  }

  func updateExchangeRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) {
    if from == self.from, to == self.to, amount == self.amountBigInt {
      self.estRate = rate
      self.slippageRate = slippageRate
    }
  }

  func updateEstimateGasLimit(for from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    if from == self.from, to == self.to, amount == self.amountBigInt {
      self.estimateGasLimit = gasLimit
    }
  }
}
