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

  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true

  fileprivate(set) var estRate: BigInt?
  fileprivate(set) var slippageRate: BigInt?
  fileprivate(set) var minRatePercent: Double = 3.0

  var isSwapAllBalance: Bool = false
  var isTappedSwapAllBalance: Bool = false

//  var estimatedRateDouble: Double {
//    guard let rate = self.estRate else { return 0.0 }
//    return Double(rate) / pow(10.0, Double(self.to.decimals))
//  }

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas

  fileprivate(set) var estimateGasLimit: BigInt = KNGasConfiguration.exchangeTokensGasLimitDefault
  var swapRates: (String, String, BigInt, [JSONDictionary]) = ("", "", BigInt(0), [])
  var currentFlatform: String = "kyber"

  init(wallet: Wallet,
       from: TokenObject,
       to: TokenObject,
       supportedTokens: [TokenObject]
    ) {
    self.wallet = wallet
    let addr = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr)?.clone() ?? KNWalletObject(address: addr)
    self.from = from.clone()
    self.to = to.clone()
    self.supportedTokens = supportedTokens.map({ return $0.clone() })
//    self.updateProdCachedRate()
  }
  // MARK: Wallet name
  var walletNameString: String {
    let address = self.walletObject.address.lowercased()
    return "|  \(address.prefix(10))...\(address.suffix(8))"
  }

  // MARK: From Token
  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.estimateGasLimit
  }

  var allFromTokenBalanceString: String {
    if self.from.isETH {
      let balance = self.balances[self.from.contract]?.value ?? BigInt(0)
      if balance <= self.feeBigInt { return "0" }
      let fee = self.allETHBalanceFee
      let availableToSwap = max(BigInt(0), balance - fee)
      let string = availableToSwap.string(
        decimals: self.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.from.decimals, 6)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.balanceText.removeGroupSeparator()
  }

  var amountFromBigInt: BigInt {
    return self.amountFrom.removeGroupSeparator().amountBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var amountToEstimate: BigInt {
    if self.amountFromBigInt.isZero, let smallAmount = EtherNumberFormatter.short.number(from: "0.001", decimals: self.from.decimals) {
      return smallAmount
    }
    return self.amountFromBigInt
  }

  var equivalentUSDAmount: BigInt? {
    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.to) {
      return usdRate.rate * self.amountToBigInt / BigInt(10).power(self.to.decimals)
    }
    return nil
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  var fromTokenIconName: String {
    return self.from.icon
  }

  var isFromTokenBtnEnabled: Bool {
    guard KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.walletObject.address) != nil else {
      // not a promo wallet, always enabled
      return true
    }
    if self.from.isPromoToken { return false }
    return true
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
      let exchangeRate: BigInt = {
        if !rate.isZero { return rate }
        return KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to) ?? BigInt(0)
      }()
      if exchangeRate.isZero { return BigInt(0) }
      let amount = self.amountToBigInt * BigInt(10).power(self.from.decimals)
      return (amount + exchangeRate - BigInt(1)) / exchangeRate
    }()
    return expectedExchange.string(
      decimals: self.from.decimals,
      minFractionDigits: self.from.decimals,
      maxFractionDigits: self.from.decimals
    ).removeGroupSeparator()
  }
//TODO: remove due to cached rate is removed now
//  var percentageRateDiff: Double {
//    guard let rate = self.cachedProdRate ?? KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to), !rate.isZero else {
//      return 0.0
//    }
//    if self.estimatedRateDouble == 0.0 { return 0.0 }
//    let marketRateDouble = Double(rate) / pow(10.0, Double(self.to.decimals))
//    let change = (self.estimatedRateDouble - marketRateDouble) / marketRateDouble * 100.0
//    if change > -5.0 { return 0.0 }
//    return change
//  }

//  var differentRatePercentageDisplay: String? {
//    if self.amountFromBigInt.isZero { return nil }
//    let change = self.percentageRateDiff
//    if change >= -5.0 { return nil }
//    let display = NumberFormatterUtil.shared.displayPercentage(from: fabs(change))
//    return "\(display)%"
//  }

  // MARK: To Token
  var amountToBigInt: BigInt {
    return self.amountTo.removeGroupSeparator().amountBigInt(decimals: self.to.decimals) ?? BigInt(0)
  }

  var isToTokenBtnEnabled: Bool {
    guard let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.walletObject.address) else {
      // not a promo wallet, always enabled
      return true
    }
    if self.from.isPromoToken && self.to.symbol == destToken { return false }
    return true
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
    guard !self.amountFromBigInt.isZero else {
      return ""
    }
    let rate: BigInt? = {
      if let rate = self.estRate, !rate.isZero { return rate }
      return KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to)
    }()
    guard let expectedRate = rate else { return "" }
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return expectedRate * amount / BigInt(10).power(self.from.decimals)
    }()
    return expectedAmount.string(
      decimals: self.to.decimals,
      minFractionDigits: min(self.to.decimals, 6),
      maxFractionDigits: min(self.to.decimals, 6)
    ).removeGroupSeparator()
  }

  func tokenButtonText(isSource: Bool) -> String {
    return isSource ? self.from.symbol : self.to.symbol
  }

  // MARK: Balance
  var balanceText: String {
    let bal: BigInt = self.balance?.value ?? BigInt(0)
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }

  var balanceTextString: String {
    let balanceText = NSLocalizedString("balance", value: "Balance", comment: "")
    return "\(self.from.symbol) \(balanceText)".uppercased()
  }

  // MARK: Rate
  var exchangeRateText: String {
    let rateString: String = self.getSwapRate(from: self.from.address.lowercased(), to: self.to.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    let rate = BigInt(rateString)
    if let notNilRate = rate {
      return notNilRate.isZero ? "---" : "Rate: 1\(self.from.symbol) = \(notNilRate.displayRate(decimals: self.to.decimals))\(self.to.symbol)"
    } else {
      return "---"
    }
  }

  var minRate: BigInt? {
    guard let estRate = self.estRate else { return nil }
    return estRate * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var slippageRateText: String? {
    return self.slippageRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: min(self.to.decimals, 9))
  }

  // MARK: Gas Price
  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }

  // MARK: Verify data
  // Amount should > 0 and <= balance
  var isAmountTooSmall: Bool {
    if self.amountFromBigInt <= BigInt(0) { return true }
    if self.from.isETH || self.from.isWETH {
      return self.amountFromBigInt < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    if self.to.isETH || self.to.isWETH {
      return self.amountToBigInt < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    let ethRate: BigInt = {
      let cacheRate = KNRateCoordinator.shared.ethRate(for: self.from)
      return cacheRate?.rate ?? BigInt(0)
    }()
    if ethRate.isZero && self.estRate != nil && self.estRate?.isZero == false {
      return false
    }
    let valueInETH = ethRate * self.amountFromBigInt
    let valueMin = BigInt(0.001 * Double(EthereumUnit.ether.rawValue)) * BigInt(10).power(self.from.decimals)
    return valueInETH < valueMin
  }

  var isBalanceEnough: Bool {
    if self.amountFromBigInt > self.balance?.value ?? BigInt(0) { return false }
    return true
  }

  var isAmountTooBig: Bool {
    if !self.isBalanceEnough { return true }
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
  var isSlippageRateValid: Bool {
    if self.slippageRate == nil || self.slippageRate?.isZero == true { return false }
    return true
  }

  var isRateValid: Bool {
    if self.estRate == nil || self.estRate?.isZero == true { return false }
    if self.slippageRate == nil || self.slippageRate?.isZero == true { return false }
    return true
  }

  var isPairUnderMaintenance: Bool {
    let cachedRate = KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to) ?? BigInt(0)
    let estRate = self.estRate ?? BigInt(0)
    return estRate.isZero && cachedRate.isZero
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

  var amountFromStringParameter: String {
    var param = self.amountFrom.removeGroupSeparator()
    let decimals: Character = EtherNumberFormatter.short.decimalSeparator.first!
    if String(decimals) != "." {
      param = param.replacingOccurrences(of: String(decimals), with: ".")
    }
    return param
  }

  var gasFeeString: String {
    let fee = self.gasPrice * self.estimateGasLimit
    let feeString: String = fee.displayRate(decimals: 18)
    var typeString = ""
    switch self.selectedGasPriceType {
    case .superFast:
      typeString = "super.fast".toBeLocalised().uppercased()
    case .fast:
      typeString = "fast".toBeLocalised().uppercased()
    case .medium:
      typeString = "regular".toBeLocalised().uppercased()
    case .slow:
      typeString = "slow".toBeLocalised().uppercased()
    default:
      break
    }
    return "Gas fee: \(feeString) ETH (\(typeString))"
  }

  var slippageString: String {
    let doubleStr = String(format: "%.2f", self.minRatePercent)
    return "Slippage: \(doubleStr)%"
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)

    if let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: address), let ptToken = KNSupportedTokenStorage.shared.ptToken {
      self.from = ptToken.clone()
      self.to = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == destToken })?.clone() ?? self.eth
    } else {
      // not a promo wallet
      self.from = self.eth
      self.to = self.knc
    }

    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true
    self.isSwapAllBalance = false

    self.balances = [:]
    self.balance = nil

    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = self.getDefaultGasLimit(for: self.from, to: self.to)
//    self.updateProdCachedRate()
  }

  func updateWalletObject() {
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.walletObject.address)?.clone() ?? self.walletObject
  }

  func swapTokens() {
    swap(&self.from, &self.to)
    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true
    self.isSwapAllBalance = false

    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = self.getDefaultGasLimit(for: self.from, to: self.to)
    self.balance = self.balances[self.from.contract]
//    self.updateProdCachedRate()
  }

  func updateSelectedToken(_ token: TokenObject, isSource: Bool) {
    if isSource {
      self.from = token.clone()
    } else {
      self.to = token.clone()
    }
    if self.isFocusingFromAmount && isSource {
      // focusing on from amount, and from token is changed, reset amount
      self.amountFrom = ""
      self.isSwapAllBalance = false
    } else if !self.isFocusingFromAmount && !isSource {
      // focusing on to amount, and to token is changed, reset to amount
      self.amountTo = ""
    }
    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = self.getDefaultGasLimit(for: self.from, to: self.to)
    self.balance = self.balances[self.from.contract]
//    self.updateProdCachedRate()
  }

  func updateFocusingField(_ isSource: Bool) {
    self.isFocusingFromAmount = isSource
  }

  func updateAmount(_ amount: String, isSource: Bool, forSwapAllETH: Bool = false) {
    if isSource {
      self.amountFrom = amount
      guard !forSwapAllETH else { return }
      self.isSwapAllBalance = false
    } else {
      self.amountTo = amount
    }
  }

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      if let oldBalance = self.balance, oldBalance.value != bal.value { self.isSwapAllBalance = false }
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
  }

  @discardableResult
  func updateExchangeRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) -> Bool {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    if from == self.from, to == self.to, !isAmountChanged {
      self.estRate = rate
      self.slippageRate = slippageRate
      return true
    }
    return false
  }

  func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }

  func updateEstimateGasLimit(for from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    if from == self.from, to == self.to, !self.isAmountFromChanged(newAmount: amount, oldAmount: self.amountFromBigInt) {
      self.estimateGasLimit = gasLimit
    }
  }

  func getDefaultGasLimit(for from: TokenObject, to: TokenObject) -> BigInt {
    return KNGasConfiguration.calculateDefaultGasLimit(from: from, to: to)
  }

  // if different less than 3%, consider as no changes
  private func isAmountFromChanged(newAmount: BigInt, oldAmount: BigInt) -> Bool {
    if oldAmount == newAmount { return false }
    let different = abs(oldAmount - newAmount)
    if different <= oldAmount * BigInt(3) / BigInt(100) { return false }
    let doubleValue = Double(newAmount) / pow(10.0, Double(self.from.decimals))
    return !(oldAmount.isZero && doubleValue == 0.001)
  }

  func getHint(from: String, to: String, amount: BigInt, platform: String) -> String {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    guard from == self.swapRates.0, to == self.swapRates.1, !isAmountChanged else {
      return ""
    }

    let rateDict = self.swapRates.3.first { (element) -> Bool in
      if let platformString = element["platform"] as? String {
        return platformString == platform
      } else {
        return false
      }
    }
    if let rateString = rateDict?["hint"] as? String {
      return rateString
    } else {
      return ""
    }
  }

  func getSwapRate(from: String, to: String, amount: BigInt, platform: String) -> String {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()

    guard from == self.swapRates.0, to == self.swapRates.1, !isAmountChanged else {
      return "0"
    }

    let rateDict = self.swapRates.3.first { (element) -> Bool in
      if let platformString = element["platform"] as? String {
        return platformString == platform
      } else {
        return false
      }
    }
    if let rateString = rateDict?["rate"] as? String {
      return rateString
    } else {
      return ""
    }
  }

  func resetSwapRates() {
    self.swapRates = ("", "", BigInt(0), [])
  }

  func updateSwapRates(from: TokenObject, to: TokenObject, amount: BigInt, rates: [JSONDictionary]) {
    guard from.isEqual(self.from), to.isEqual(self.to) else {
      return
    }
    self.swapRates = (from.address.lowercased(), to.address.lowercased(), amount, rates)
    if rates.count == 1 {
      let dict = rates.first
      if let platformString = dict?["platform"] as? String {
        self.currentFlatform = platformString
      }
    }
  }

  // MARK: TUTORIAL
  var currentTutorialStep: Int = 1
}
