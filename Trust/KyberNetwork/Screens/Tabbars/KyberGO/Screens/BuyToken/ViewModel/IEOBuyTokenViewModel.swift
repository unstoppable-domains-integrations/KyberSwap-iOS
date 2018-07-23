// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct IEOBuyTokenViewModel {
  let defaultTokenIconImg = UIImage(named: "default_token")

  fileprivate(set) var walletObject: KNWalletObject

  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: IEOObject

  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true

  fileprivate(set) var ethRate: BigInt?
  fileprivate(set) var estTokenRate: BigInt?
  fileprivate(set) var minTokenRate: BigInt?

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .fast
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas

  fileprivate(set) var estimateGasLimit: BigInt = KNGasConfiguration.transferETHBuyTokenSaleGasLimitDefault

  init(from: TokenObject = KNSupportedTokenStorage.shared.ethToken,
       to: IEOObject,
       walletObject: KNWalletObject
    ) {
    self.walletObject = walletObject
    self.from = from
    self.to = to
    self.ethRate = self.to.rate.fullBigInt(decimals: self.to.tokenDecimals)
    self.estTokenRate = self.ethRate
    self.minTokenRate = self.ethRate
  }

  var estRate: BigInt? {
    if self.from.isETH { return self.ethRate }
    if let ethRate = self.ethRate, let tokenRate = self.estTokenRate {
      return ethRate * tokenRate / BigInt(EthereumUnit.ether.rawValue)
    }
    return nil
  }

  var minRate: BigInt? {
    if self.from.isETH { return nil }
    if let ethRate = self.ethRate, let tokenRate = self.minTokenRate {
      return ethRate * tokenRate / BigInt(EthereumUnit.ether.rawValue)
    }
    return nil
  }

  var estETHAmount: BigInt? {
    if self.from.isETH { return self.amountFromBigInt }
    if let ethRate = self.ethRate {
      return self.amountToBigInt * BigInt(EthereumUnit.ether.rawValue) / ethRate
    }
    return nil
  }

  // MARK: From Token
  var allFromTokenBalanceString: String {
    return self.balance?.value.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: self.from.decimals
      ) ?? ""
  }

  var amountFromBigInt: BigInt {
    return self.amountFrom.fullBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var fromTokenIconName: String {
    return self.from.icon
  }

  var fromTokenBtnTitle: String {
    return self.from.symbol
  }

  // when user wants to fix received amount
  var expectedExchangeAmountText: String {
    guard let rate = self.estRate, !self.amountToBigInt.isZero else {
      return ""
    }
    let expectedExchange: BigInt = {
      let amount = self.amountTo.fullBigInt(decimals: self.to.tokenDecimals) ?? BigInt(0)
      return amount * BigInt(10).power(self.from.decimals) / rate
    }()
    return expectedExchange.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: self.from.decimals
    )
  }

  // MARK: To Token
  var amountToBigInt: BigInt {
    return self.amountTo.fullBigInt(decimals: self.to.tokenDecimals) ?? BigInt(0)
  }

  var toTokenBtnTitle: String {
    return self.to.tokenSymbol
  }

  var toTokenIconName: String {
    return self.to.icon
  }

  var amountTextFieldColor: UIColor {
    return self.isAmountValid ? UIColor(hex: "31CB9E") : UIColor.red
  }

  var expectedReceivedAmountText: String {
    guard let rate = self.estRate, !self.amountFromBigInt.isZero else {
      return ""
    }
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return rate * amount / BigInt(10).power(self.from.decimals)
    }()
    return expectedAmount.string(decimals: self.to.tokenDecimals, minFractionDigits: 1, maxFractionDigits: 4)
  }

  func tokenButtonAttributedText(isSource: Bool) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.medium),
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
      ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular),
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
      ]
    let symbol = isSource ? self.from.symbol : self.to.tokenSymbol
    let name = isSource ? self.from.name : self.to.tokenName
    attributedString.append(NSAttributedString(string: symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(name)", attributes: nameAttributes))
    return attributedString
  }

  // MARK: Balance
  var balanceText: String {
    let bal: BigInt = self.balance?.value ?? BigInt(0)
    return "\(bal.shortString(decimals: self.from.decimals))"
  }

  var balanceTextString: String {
    return "\(self.from.symbol) Balance"
  }

  // MARK: Rate
  var exchangeRateText: String {
    let rateString: String = self.estRate?.string(decimals: self.to.tokenDecimals, minFractionDigits: 2, maxFractionDigits: 9) ?? "---"
    return "\(rateString)"
  }

  // MARK: Gas Price
  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }

  // MARK: Verify data
  // Amount should > 0 and <= balance
  var isAmountTooSmall: Bool {
    if let estETHAmount = self.estETHAmount {
      return estETHAmount < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    return true
  }

  var isAmountTooBig: Bool {
    // TODO: Check user cap
    return self.amountFromBigInt > (self.balance?.value ?? BigInt(0))
  }

  var isAmountValid: Bool {
    return !self.isAmountTooSmall && !self.isAmountTooBig
  }

  // rate should not be nil and greater than zero
  var isRateValid: Bool {
    if self.estRate == nil || self.estRate?.isZero == true { return false }
    if !self.from.isETH && (self.minTokenRate == nil || self.minTokenRate?.isZero == true) { return false }
    return true
  }

  var walletButtonTitle: String {
    return "\(self.walletObject.name) - \(self.walletObject.address.prefix(7))....\(self.walletObject.address.suffix(5))"
  }

  var transaction: IEODraftTransaction {
    return IEODraftTransaction(
      token: self.from,
      ieo: self.to,
      amount: self.amountFromBigInt,
      wallet: self.walletObject,
      gasPrice: self.gasPrice,
      gasLimit: self.estimateGasLimit,
      estRate: self.estRate,
      minRate: self.from.isETH ? nil : self.minTokenRate,
      maxDestAmount: self.estETHAmount,
      expectedReceived: self.amountTo
    )
  }

  // MARK: Update data
  mutating func updateWallet(_ walletObject: KNWalletObject) {
    self.walletObject = walletObject

    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true

    self.balances = [:]
    self.balance = nil
  }

  mutating func updateFocusingField(_ isSource: Bool) {
    self.isFocusingFromAmount = isSource
  }

  mutating func updateAmount(_ amount: String, isSource: Bool) {
    if isSource {
      self.amountFrom = amount
    } else {
      self.amountTo = amount
    }
  }

  mutating func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      self.balance = bal
    }
  }

  mutating func updateBalance(_ balance: Balance) {
    self.balance = balance
  }

  mutating func updateEstimateETHRate(_ rate: BigInt) {
    self.ethRate = rate
  }

  mutating func updateEstimatedTokenRate(_ estRate: BigInt, minRate: BigInt) {
    self.estTokenRate = estRate
    self.minTokenRate = minRate
  }

  mutating func updateEstimateGasLimit(_ gasLimit: BigInt) {
    self.estimateGasLimit = gasLimit
  }

  mutating func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    default: break
    }
  }

  mutating func updateBuyToken(_ token: TokenObject) {
    if token == self.from { return }
    self.from = token
    if self.from.isETH {
      self.minTokenRate = self.ethRate
      self.estTokenRate = self.ethRate
    } else if let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.from) {
      // Use rate from cached server while waiting for rate from nodes
      let rate = KNRate.rateETH(from: trackerRate)
      self.estTokenRate = rate.rate
      self.minTokenRate = rate.minRate
    }
    self.amountFrom = ""
    if self.isFocusingFromAmount { self.amountTo = "" }
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
    self.balance = self.balances[self.from.contract]
  }

  // update when set gas price
  mutating func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
    self.selectedGasPriceType = .custom
  }
}
