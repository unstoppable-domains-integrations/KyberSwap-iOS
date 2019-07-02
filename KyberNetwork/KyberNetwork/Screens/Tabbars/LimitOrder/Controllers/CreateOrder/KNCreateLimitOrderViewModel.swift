// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNCreateLimitOrderViewModel {

  let defaultTokenIconImg = UIImage(named: "default_token")
  let eth = KNSupportedTokenStorage.shared.ethToken
  let knc = KNSupportedTokenStorage.shared.kncToken
  let weth = KNSupportedTokenStorage.shared.wethToken

  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject
  fileprivate var supportedTokens: [TokenObject] = []

  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: TokenObject
  fileprivate(set) var nonce: String?

  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var targetRate: String = ""

  fileprivate(set) var rateFromNode: BigInt?
  fileprivate(set) var cachedProdRate: BigInt?

  fileprivate(set) var prevFocusTextFieldTag: Int = 2
  fileprivate(set) var focusTextFieldTag: Int = 2

  fileprivate(set) var relatedOrders: [KNOrderObject] = []
  fileprivate(set) var cancelSuggestOrders: [KNOrderObject] = []

  var cancelOrder: KNOrderObject?

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
    self.feePercentage = 0
    self.nonce = nil
    self.supportedTokens = supportedTokens
    self.updateProdCachedRate()
  }

  // MARK: Wallet name
  var walletNameString: String {
    let addr = self.walletObject.address.lowercased()
    return "| \(self.walletObject.name) - \(addr.prefix(6))...\(addr.suffix(4))"
  }

  // MARK: From Token
  var fromSymbol: String {
    return self.from.isETH || self.from.isWETH ? "ETH*" : self.from.symbol
  }

  var toSymbol: String {
    return self.to.isETH || self.to.isWETH ? "ETH*" : self.to.symbol
  }

  var allFromTokenBalanceString: String {
    if !(self.from.isETH || self.from.isWETH) { return self.balanceText }
    let fee: BigInt = {
      if let bal = self.balances[self.eth.contract]?.value, !bal.isZero {
        return KNGasCoordinator.shared.fastKNGas * BigInt(600_000) // approve + convet if needed
      }
      return BigInt(0)
    }()
    let bal: BigInt = max(BigInt(0), self.availableBalance - fee)
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    )
    return "\(string.prefix(12))"
  }

  var amountFromBigInt: BigInt {
    return self.amountFrom.removeGroupSeparator().fullBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  func amountFromWithPercentage(_ percentage: Int) -> BigInt {
    let amount = self.availableBalance * BigInt(percentage) / BigInt(100)
    if !(self.from.isETH || self.from.isWETH) { return amount }
    let fee: BigInt = {
      if let bal = self.balances[self.eth.contract]?.value, !bal.isZero {
        return KNGasCoordinator.shared.fastKNGas * BigInt(600_000) // approve + convet if needed
      }
      return BigInt(0)
    }()
    return min(amount, max(0, self.availableBalance - fee))
  }

  var amountToBigInt: BigInt {
    return self.amountTo.removeGroupSeparator().fullBigInt(decimals: self.to.decimals) ?? BigInt(0)
  }

  var estimateAmountFromBigInt: BigInt {
    let rate = self.targetRateBigInt
    if rate.isZero { return BigInt(0) }
    let amountTo = self.amountToBigInt
    return amountTo * BigInt(10).power(self.from.decimals) / rate
  }

  var shouldAmountFromChange: Bool {
    return self.prevFocusTextFieldTag != 0 && self.focusTextFieldTag != 0
  }

  var estimateAmountToBigInt: BigInt {
    let rate = self.targetRateBigInt
    if rate.isZero { return BigInt(0) }
    return self.amountFromBigInt * rate / BigInt(10).power(self.from.decimals)
  }

  var shouldAmountToChange: Bool {
    return self.prevFocusTextFieldTag != 1 && self.focusTextFieldTag != 1
  }

  func tokenButtonAttributedText(isSource: Bool) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 22),
      NSAttributedStringKey.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
      NSAttributedStringKey.kern: 0.0,
    ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 13),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.gray,
      NSAttributedStringKey.kern: 0.0,
    ]
    let symbol: String = isSource ? self.fromSymbol : self.toSymbol
    let name = isSource ? self.from.name : self.to.name
    attributedString.append(NSAttributedString(string: symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(name)", attributes: nameAttributes))
    return attributedString
  }

  // MARK: Balance
  var availableBalance: BigInt {
    let balance: BigInt = {
      if self.from.isWETH {
        let wethBalance = self.balance?.value ?? BigInt(0)
        let ethBalance = self.balances[self.eth.contract]?.value ?? BigInt(0)
        return wethBalance + ethBalance
      }
      return self.balance?.value ?? BigInt(0)
    }()
    var availableAmount: Double = Double(balance) / pow(10.0, Double(self.from.decimals))
    let allOrders = KNLimitOrderStorage.shared.orders
    allOrders.forEach({
      if ($0.state == .open || $0.state == .inProgress)
        && $0.sourceToken.lowercased() == self.from.symbol.lowercased()
        && $0.sender.lowercased() == self.walletObject.address.lowercased() {
        availableAmount -= $0.sourceAmount
      }
    })
    availableAmount = max(availableAmount, 0.0)
    return BigInt(availableAmount * pow(10.0, Double(self.from.decimals)))
  }

  var balanceText: String {
    let bal: BigInt = self.availableBalance
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    ).removeGroupSeparator()
    return "\(string.prefix(12))"
  }

  var balanceTextString: String {
    return "\(self.fromSymbol) Available".toBeLocalised().uppercased()
  }

  var isBalanceEnough: Bool {
    if self.amountFromBigInt > self.availableBalance { return false }
    return true
  }

  var equivalentETHAmount: BigInt {
    if self.amountFromBigInt <= BigInt(0) { return BigInt(0) }
    if self.from.isETH || self.from.isWETH {
      return self.amountFromBigInt
    }
    if self.to.isETH || self.to.isWETH {
      return self.amountToBigInt
    }
    let ethRate: BigInt = {
      let cacheRate = KNTrackerRateStorage.shared.trackerRate(for: self.from)
      return BigInt((cacheRate?.rateETHNow ?? 0.0) * pow(10.0, 18.0))
    }()
    let valueInETH = ethRate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
    return valueInETH
  }

  var isConvertingETHToWETHNeeded: Bool {
    if !self.from.isWETH { return false }
    let balance = self.balance?.value ?? BigInt(0)

    var availableAmount: Double = Double(balance) / pow(10.0, 18.0)
    let allOrders = KNLimitOrderStorage.shared.orders
    allOrders.forEach({
      if ($0.state == .open || $0.state == .inProgress)
        && $0.sourceToken.lowercased() == self.from.symbol.lowercased()
        && $0.sender.lowercased() == self.walletObject.address.lowercased() {
        availableAmount -= $0.sourceAmount
      }
    })
    availableAmount = max(availableAmount, 0.0)

    return BigInt(availableAmount * pow(10.0, 18.0)) < self.amountFromBigInt
  }

  var minAmountToConvert: BigInt {
    if !self.from.isWETH { return BigInt(0) }
    let balance = self.balance?.value ?? BigInt(0)

    var availableAmount: Double = Double(balance) / pow(10.0, 18.0)
    let allOrders = KNLimitOrderStorage.shared.orders
    allOrders.forEach({
      if ($0.state == .open || $0.state == .inProgress)
        && $0.sourceToken.lowercased() == self.from.symbol.lowercased()
        && $0.sender.lowercased() == self.walletObject.address.lowercased() {
        availableAmount -= $0.sourceAmount
      }
    })
    availableAmount = max(availableAmount, 0.0)

    let availableBal = BigInt(availableAmount * pow(10.0, 18.0))

    if availableBal < self.amountFromBigInt { return self.amountFromBigInt - availableBal }
    return BigInt(0)
  }

  var isAmountTooBig: Bool {
    if !self.isBalanceEnough { return true }
    let maxValueInETH = BigInt(10.0 * Double(EthereumUnit.ether.rawValue))
    return maxValueInETH < self.equivalentETHAmount
  }

  var isAmountTooSmall: Bool {
    let minValueInETH = BigInt(0.5 * Double(EthereumUnit.ether.rawValue))
    return minValueInETH > self.equivalentETHAmount
  }

  // MARK: Rate
  var targetRateBigInt: BigInt {
    return self.targetRate.removeGroupSeparator().fullBigInt(decimals: self.to.decimals) ?? BigInt(0)
  }

  var targetRateDouble: Double {
    return Double(targetRateBigInt) / pow(10.0, Double(self.to.decimals))
  }

  var estimateTargetRateBigInt: BigInt {
    let amountFrom = self.amountFromBigInt
    if amountFrom.isZero { return BigInt(0) }
    let amountTo = self.amountToBigInt
    return amountTo * BigInt(10).power(self.from.decimals) / amountFrom
  }

  var shouldTargetRateChange: Bool {
    return self.prevFocusTextFieldTag != 2 && self.focusTextFieldTag != 2
  }

  var exchangeRateText: String {
    let rate: BigInt? = self.rateFromNode ?? self.cachedProdRate
    if let rateText = rate?.displayRate(decimals: self.to.decimals) {
      return "1 \(self.fromSymbol) = \(rateText) \(self.toSymbol)"
    }
    return "---"
  }

  var estimatedRateDouble: Double {
    guard let rate = self.rateFromNode else { return 0.0 }
    return Double(rate) / pow(10.0, Double(self.to.decimals))
  }

  var isRateTooSmall: Bool {
    return self.targetRateBigInt.isZero
  }

  var isRateTooBig: Bool {
    let curRate = self.rateFromNode ?? self.cachedProdRate ?? BigInt(0)
    return self.targetRateBigInt > curRate * BigInt(10)
  }

  var percentageRateDiff: Double {
    guard let rate = self.targetRate.fullBigInt(decimals: self.to.decimals) else { return 0.0 }
    let marketRate = self.estimatedRateDouble
    if marketRate == 0.0 { return 0.0 }
    let targetRateDouble = Double(rate) / pow(10.0, Double(self.to.decimals))
    return (targetRateDouble - marketRate) / marketRate * 100.0
  }

  var differentRatePercentageDisplay: String? {
    let change = self.percentageRateDiff
    let display = NumberFormatterUtil.shared.displayPercentage(from: fabs(change))
    return "\(display)%"
  }

  var displayRateCompareAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let rateChange = self.percentageRateDiff
    if fabs(rateChange) < 0.1 { return attributedString }
    guard let rate = self.differentRatePercentageDisplay else { return attributedString }
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 98, green: 107, blue: 134),
    ]
    let higherAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.shamrock,
    ]
    let lowerAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.strawberry,
    ]
    attributedString.append(NSAttributedString(string: "Your target price is".toBeLocalised(), attributes: normalAttributes))
    if rateChange > 0 {
      attributedString.append(NSAttributedString(string: " \(rate) ", attributes: higherAttributes))
      attributedString.append(NSAttributedString(string: "higher than current Market rate".toBeLocalised(), attributes: normalAttributes))
    } else {
      attributedString.append(NSAttributedString(string: " \(rate) ", attributes: lowerAttributes))
      attributedString.append(NSAttributedString(string: "lower than current Market rate".toBeLocalised(), attributes: normalAttributes))
    }
    return attributedString
  }

  // MARK: Fee
  var feePercentage: Double = 0 // 10000 as in SC

  var displayFeeString: String {
    let feeBigInt = BigInt(Double(self.amountFromBigInt) * self.feePercentage)
    let feeDisplay = feeBigInt.displayRate(decimals: self.from.decimals)
    let amountString = self.amountFromBigInt.isZero ? "0" : self.amountFrom
    let fromSymbol = self.fromSymbol
    let fee = NumberFormatterUtil.shared.displayPercentage(from: feePercentage * 100.0)
    let feeText = NSLocalizedString("fee", value: "Fee", comment: "")
    return "\(feeText): \(feeDisplay) \(fromSymbol) (\(fee)% of \(amountString.prefix(12)) \(fromSymbol))"
  }

  var suggestBuyText: String {
    return "Hold from 2000 KNC to get discount for your orders.".toBeLocalised()
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)

    self.amountFrom = ""
    self.amountTo = ""
    self.targetRate = ""

    self.feePercentage = 0
    self.nonce = nil

    self.balances = [:]
    self.balance = nil

    self.rateFromNode = nil
    self.updateProdCachedRate()
  }

  func updateWalletObject() {
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.walletObject.address) ?? self.walletObject
  }

  func updateFocusTextField(_ tag: Int) {
    if self.focusTextFieldTag == tag { return }
    self.prevFocusTextFieldTag = {
      if tag != 2 { return 2 } // rate is the highest priority
      return self.focusTextFieldTag
    }()
    self.focusTextFieldTag = tag
  }

  func swapTokens() {
    swap(&self.from, &self.to)
    if self.from.isETH, let weth = self.weth { self.from = weth } // switch to weth
    if self.to.isETH, let weth = self.weth { self.to = weth }
    self.amountFrom = ""
    self.amountTo = ""
    self.targetRate = ""
    self.balance = self.balances[self.from.contract]
    self.feePercentage = 0
    self.nonce = nil

    self.rateFromNode = nil
    self.updateProdCachedRate()
  }

  func updateAmount(_ amount: String, isSource: Bool) {
    if isSource {
      self.amountFrom = amount
    } else {
      self.amountTo = amount
    }
  }

  func updateTargetRate(_ rate: String) {
    self.targetRate = rate
    self.cancelSuggestOrders = self.relatedOrders.filter({ return $0.targetPrice > self.targetRateDouble })
  }

  func updateSelectedToken(_ token: TokenObject, isSource: Bool) {
    if isSource {
      self.from = token
      self.feePercentage = 0
    } else {
      self.to = token
    }
    self.nonce = nil
    self.balance = self.balances[self.from.contract]
    self.rateFromNode = nil
    self.updateProdCachedRate()
  }

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      self.balance = bal
    }
  }

  func updateProdCachedRate(_ rate: BigInt? = nil) {
    self.cachedProdRate = rate ?? KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to)
  }

  @discardableResult
  func updateExchangeRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) -> Bool {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    if from == self.from, to == self.to, !isAmountChanged {
      self.rateFromNode = rate.isZero ? nil : rate
      return true
    }
    return false
  }

  // Update order with same sender, src and dest address
  func updateRelatedOrders(_ orders: [KNOrderObject]) {
    let fromTime: TimeInterval = {
      if let date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) {
        return date.timeIntervalSince1970
      }
      return Date().timeIntervalSince1970 - 3.0 * 30.0 * 24.0 * 60.0 * 60.0
    }()
    self.relatedOrders = orders
      .filter({ return $0.state == .open || $0.state == .inProgress })
      .filter({ return $0.dateToDisplay.timeIntervalSince1970 >= fromTime })
      .sorted(by: { return $0.dateToDisplay > $1.dateToDisplay })
    self.cancelSuggestOrders = self.relatedOrders.filter({ return $0.targetPrice > self.targetRateDouble })
  }
}
