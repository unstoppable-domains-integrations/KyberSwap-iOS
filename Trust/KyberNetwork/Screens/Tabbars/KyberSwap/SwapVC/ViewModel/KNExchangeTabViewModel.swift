// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNExchangeTabViewModel {

  let defaultTokenIconImg = UIImage(named: "default_token")
  let eth = KNSupportedTokenStorage.shared.ethToken
  let knc = KNSupportedTokenStorage.shared.kncToken

  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject
  fileprivate(set) var supportedTokens: [TokenObject] = []

  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: TokenObject

  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true

  fileprivate(set) var estRate: BigInt?
  fileprivate(set) var slippageRate: BigInt?

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .fast
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas

  fileprivate(set) var estimateGasLimit: BigInt = KNGasConfiguration.exchangeTokensGasLimitDefault

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
      let amount = self.amountToBigInt
      return amount * BigInt(10).power(self.from.decimals) / rate
    }()
    return expectedExchange.string(decimals: self.from.decimals, minFractionDigits: 6, maxFractionDigits: 6)
  }

  // MARK: To Token
  var amountToBigInt: BigInt {
    return self.amountTo.fullBigInt(decimals: self.to.decimals) ?? BigInt(0)
  }

  var toTokenBtnTitle: String {
    return self.to.symbol
  }

  var toTokenIconName: String {
    return self.to.icon
  }

  var amountTextFieldColor: UIColor {
    return self.isAmountValid ? UIColor.Kyber.green : UIColor.red
  }

  var expectedReceivedAmountText: String {
    guard let rate = self.estRate, !self.amountFromBigInt.isZero else {
      return ""
    }
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return rate * amount / BigInt(10).power(self.from.decimals)
    }()
    return expectedAmount.string(decimals: self.to.decimals, minFractionDigits: 6, maxFractionDigits: 6)
  }

  func tokenButtonAttributedText(isSource: Bool) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 22)!,
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.gray,
    ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont(name: "SFProText-Regular", size: 13)!,
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.gray,
    ]
    let symbol = isSource ? self.from.symbol : self.to.symbol
    let name = isSource ? self.from.name : self.to.name
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
    let rateString: String = self.estRate?.string(decimals: self.to.decimals, minFractionDigits: 2, maxFractionDigits: 9) ?? "---"
    return "\(rateString)"
  }

  // MARK: Gas Price
  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }

  // MARK: Verify data
  // Amount should > 0 and <= balance
  var isAmountTooSmall: Bool {
    if self.amountFromBigInt <= BigInt(0) { return true }
    if self.from.isETH {
      return self.amountFromBigInt < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    if self.to.isETH {
      return self.amountToBigInt < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    let ethRate: BigInt = {
      if let rate = KNTrackerRateStorage.shared.trackerRate(for: self.from) {
        return KNRate(source: "", dest: "", rate: rate.rateETHNow, decimals: 18).rate
      }
      return BigInt(0)
    }()
    let valueInETH = ethRate * self.amountFromBigInt
    let valueMin = BigInt(0.001 * Double(EthereumUnit.ether.rawValue)) * BigInt(10).power(self.from.decimals)
    return valueInETH < valueMin
  }

  var isAmountTooBig: Bool {
    if self.amountFromBigInt > self.balance?.value ?? BigInt(0) { return true }
    if self.estRate?.isZero == true { return true }
    return false
  }

  var isAmountValid: Bool {
    return !self.isAmountTooSmall && !self.isAmountTooBig
  }

  // rate should not be nil and greater than zero
  var isRateValid: Bool {
    if self.estRate == nil || self.estRate?.isZero == true { return false }
    if self.slippageRate == nil || self.slippageRate?.isZero == true { return false }
    return true
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)

    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true

    self.balances = [:]
    self.balance = nil

    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
  }

  func updateWalletObject() {
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.walletObject.address) ?? self.walletObject
  }

  func swapTokens() {
    swap(&self.from, &self.to)
    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true

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
    if self.isFocusingFromAmount && isSource {
      // focusing on from amount, and from token is changed, reset amount
      self.amountFrom = ""
    } else if !self.isFocusingFromAmount && !isSource {
      // focusing on to amount, and to token is changed, reset to amount
      self.amountTo = ""
    }
    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
    self.balance = self.balances[self.from.contract]
  }

  func updateEstimatedRateFromCachedIfNeeded() {
    guard let rate = KNRateCoordinator.shared.getRate(from: self.from, to: self.to), self.estRate == nil, self.slippageRate == nil else { return }
    self.estRate = rate.rate
    self.slippageRate = rate.minRate
  }

  func updateFocusingField(_ isSource: Bool) {
    self.isFocusingFromAmount = isSource
  }

  func updateAmount(_ amount: String, isSource: Bool) {
    if isSource {
      self.amountFrom = amount
    } else {
      self.amountTo = amount
    }
  }

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      self.balance = bal
    }
  }

  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    default: break
    }
  }

  // update when set gas price
  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
    self.selectedGasPriceType = .custom
  }

  func updateExchangeRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) {
    if from == self.from, to == self.to, amount == self.amountFromBigInt {
      self.estRate = rate
      self.slippageRate = slippageRate
    }
  }

  func updateEstimateGasLimit(for from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    if from == self.from, to == self.to, amount == self.amountFromBigInt {
      self.estimateGasLimit = gasLimit
    }
  }
}
