// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KSwapViewModel {

  let defaultTokenIconImg = UIImage(named: "default_token")
  let eth = KNSupportedTokenStorage.shared.ethToken
  let knc = KNSupportedTokenStorage.shared.kncToken

  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject
  fileprivate var supportedTokens: [TokenObject] = []

  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: TokenObject

  fileprivate var balances: [String: Balance] = [:]
  fileprivate var balance: Balance?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true

  fileprivate(set) var userCapInWei: BigInt?
  fileprivate(set) var estRate: BigInt?
  fileprivate var slippageRate: BigInt?
  fileprivate var minRatePercent: Double?

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
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

  var headerBackgroundColor: UIColor { return KNAppStyleType.current.swapFlowHeaderColor }
  // MARK: Wallet name
  var walletNameString: String { return "| \(self.walletObject.name)" }

  // MARK: From Token
  var allFromTokenBalanceString: String {
    if self.from.isETH {
      let balance = self.balances[self.from.contract]?.value ?? BigInt(0)
      if balance <= self.feeBigInt { return "0" }
      let availableToSwap = max(BigInt(0), balance - self.feeBigInt)
      let string = availableToSwap.string(
        decimals: self.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.from.decimals, 6)
      )
      return "\(string.prefix(12))"
    }
    return self.balanceText
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
      if rate.isZero { return rate }
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
    return self.isAmountValid ? UIColor.Kyber.enygold : UIColor.red
  }

  var expectedReceivedAmountText: String {
    guard let rate = self.estRate, !self.amountFromBigInt.isZero else {
      return ""
    }
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return rate * amount / BigInt(10).power(self.from.decimals)
    }()
    return expectedAmount.string(decimals: self.to.decimals, minFractionDigits: min(self.to.decimals, 6), maxFractionDigits: min(self.to.decimals, 6))
  }

  func tokenButtonAttributedText(isSource: Bool) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 22),
      NSAttributedStringKey.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
    ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 13),
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
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    )
    return "\(string.prefix(12))"
  }

  var balanceTextString: String {
    let balanceText = NSLocalizedString("balance", value: "balance", comment: "")
    return "\(self.from.symbol) \(balanceText)"
  }

  // MARK: Rate
  var exchangeRateText: String {
    let rateString: String = self.estRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: min(self.to.decimals, 9)) ?? "---"
    return "\(rateString)"
  }

  var minRate: BigInt? {
    guard let estRate = self.estRate, let slippageRate = self.slippageRate else { return nil }
    if let percent = self.minRatePercent {
      return estRate * BigInt(percent) / BigInt(100.0)
    }
    return slippageRate
  }

  var minRateText: String? {
    return self.minRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: min(self.to.decimals, 9))
  }

  var slippageRateText: String? {
    return self.slippageRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: min(self.to.decimals, 9))
  }

  var currentMinRatePercentValue: Float {
    if let double = self.minRatePercent { return Float(floor(double)) }
    guard let estRate = self.estRate, let slippageRate = self.slippageRate, !estRate.isZero else { return 100.0 }
    return Float(floor(Double(slippageRate * BigInt(100) / estRate)))
  }

  var currentMinRatePercentText: String {
    let value = self.currentMinRatePercentValue
    return "\(Int(floor(value)))%"
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
      let cacheRate = KNRateCoordinator.shared.ethRate(for: self.from)
      return cacheRate?.rate ?? BigInt(0)
    }()
    let valueInETH = ethRate * self.amountFromBigInt
    let valueMin = BigInt(0.001 * Double(EthereumUnit.ether.rawValue)) * BigInt(10).power(self.from.decimals)
    return valueInETH < valueMin
  }

  var isBalanceEnough: Bool {
    if self.amountFromBigInt > self.balance?.value ?? BigInt(0) { return false }
    return true
  }

  var isCapEnough: Bool {
    let ethAmount: BigInt = {
      if self.from.isETH { return self.amountFromBigInt }
      if self.to.isETH { return self.amountToBigInt }
      let ethRate: BigInt = {
        let cacheRate = KNRateCoordinator.shared.ethRate(for: self.from)
        return cacheRate?.rate ?? BigInt(0)
      }()
      return ethRate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
    }()
    guard let cap = self.userCapInWei else { return false }
    return cap >= ethAmount
  }

  var isAmountTooBig: Bool {
    if !self.isBalanceEnough { return true }
    if !self.isCapEnough { return true }
    return false
  }

  var isETHSwapAmountAndFeeTooBig: Bool {
    if !self.from.isETH { return false } // not ETH
    let totalValue = self.feeBigInt + self.amountFromBigInt
    let balance = self.balances[self.from.contract]?.value ?? BigInt(0)
    return balance < totalValue
  }

  var isAmountValid: Bool {
    return !self.isAmountTooSmall && !self.isAmountTooBig
  }

  // rate should not be nil and greater than zero
  var isMinRateValid: Bool {
    if self.minRate == nil || self.minRate?.isZero == true { return false }
    return true
  }

  var isRateValid: Bool {
    if self.estRate == nil || self.estRate?.isZero == true { return false }
    if self.minRate == nil || self.minRate?.isZero == true { return false }
    return true
  }

  var feeBigInt: BigInt {
    return self.gasPrice * self.estimateGasLimit
  }

  var isHavingEnoughETHForFee: Bool {
    var fee = self.gasPrice * self.estimateGasLimit
    if self.from.isETH { fee += self.amountFromBigInt }
    let ethBal = self.balances[self.eth.contract]?.value ?? BigInt(0)
    return ethBal >= fee
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
    self.estimateGasLimit = KNGasConfiguration.calculateDefaultGasLimit(from: self.from, to: self.to)
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
    self.estimateGasLimit = KNGasConfiguration.calculateDefaultGasLimit(from: self.from, to: self.to)
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
    self.estimateGasLimit = KNGasConfiguration.calculateDefaultGasLimit(from: self.from, to: self.to)
    self.balance = self.balances[self.from.contract]
  }

  func updateEstimatedRateFromCachedIfNeeded() {
    guard let rate = KNRateCoordinator.shared.getRate(from: self.from, to: self.to), self.estRate == nil, self.slippageRate == nil else { return }
    self.estRate = rate.rate
    if rate.rate.isZero {
      self.slippageRate = rate.minRate
    } else {
      let percent = Double(rate.minRate * BigInt(100) / rate.rate)
      self.slippageRate = rate.rate * BigInt(Int(floor(percent))) / BigInt(100)
    }
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
      if rate.isZero {
        self.slippageRate = slippageRate
      } else {
        var percent = Double(slippageRate * BigInt(100) / rate)
        if percent == 0 { percent = 97.0 } // fixed: if slippage rate = 0 -> set as 97 %
        self.slippageRate = rate * BigInt(Int(floor(percent))) / BigInt(100)
      }
    }
  }

  func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }

  func updateEstimateGasLimit(for from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    if from == self.from, to == self.to, amount == self.amountFromBigInt {
      self.estimateGasLimit = gasLimit
    }
  }

  func updateUserCapInWei(cap: BigInt) {
    self.userCapInWei = cap
  }
}
