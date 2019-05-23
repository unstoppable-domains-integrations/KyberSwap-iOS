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

  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var targetRate: String = ""

  fileprivate(set) var rateFromNode: BigInt?
  fileprivate(set) var cachedProdRate: BigInt?

  fileprivate(set) var focusTextFieldTag: Int = 0

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
    self.supportedTokens = supportedTokens
    self.updateProdCachedRate()
  }

  // MARK: Wallet name
  var walletNameString: String { return "| \(self.walletObject.name)" }

  // MARK: From Token
  var allFromTokenBalanceString: String {
    if self.from.isETH {
      let balance = self.balances[self.from.contract]?.value ?? BigInt(0)
      let string = balance.string(
        decimals: self.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.from.decimals, 6)
      )
      return "\(string.prefix(12))"
    }
    return self.balanceText
  }

  var amountFromBigInt: BigInt {
    return self.amountFrom.removeGroupSeparator().fullBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  func amountFromWithPercentage(_ percentage: Int) -> BigInt {
    return (self.balance?.value ?? BigInt(0)) * BigInt(percentage) / BigInt(100)
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

  var estimateAmountToBigInt: BigInt {
    let rate = self.targetRateBigInt
    if rate.isZero { return BigInt(0) }
    return self.amountFromBigInt * rate / BigInt(10).power(self.from.decimals)
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
    return "\(self.from.symbol) \(balanceText)".uppercased()
  }

  var isBalanceEnough: Bool {
    if self.amountFromBigInt > self.balance?.value ?? BigInt(0) { return false }
    return true
  }

  var equivalentETHAmount: BigInt {
    if self.amountFromBigInt <= BigInt(0) { return BigInt(0) }
    if self.from.isETH {
      return self.amountFromBigInt
    }
    if self.to.isETH {
      return self.amountToBigInt
    }
    let ethRate: BigInt = {
      let cacheRate = KNTrackerRateStorage.shared.trackerRate(for: self.from)
      return BigInt((cacheRate?.rateETHNow ?? 0.0) * pow(10.0, 18.0))
    }()
    let valueInETH = ethRate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
    return valueInETH
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

  var exchangeRateText: String {
    let rate: BigInt? = self.rateFromNode
    if let rateText = rate?.displayRate(decimals: self.to.decimals) {
      return "1 \(self.from.symbol) = \(rateText) \(self.to.symbol)"
    }
    return "---"
  }

  var estimatedRateDouble: Double {
    guard let rate = self.rateFromNode else { return 0.0 }
    return Double(rate) / pow(10.0, Double(self.to.decimals))
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
    attributedString.append(NSAttributedString(string: "Your target price is ".toBeLocalised(), attributes: normalAttributes))
    if rateChange > 0 {
      attributedString.append(NSAttributedString(string: rate, attributes: higherAttributes))
      attributedString.append(NSAttributedString(string: " higher than current Market rate".toBeLocalised(), attributes: normalAttributes))
    } else {
      attributedString.append(NSAttributedString(string: rate, attributes: lowerAttributes))
      attributedString.append(NSAttributedString(string: " lower than current Market rate".toBeLocalised(), attributes: normalAttributes))
    }
    return attributedString
  }

  // MARK: Fee
  var feePercentage: Int { return 10 } // uint: 10000 as in SC

  var displayFeeString: String {
    let feeBigInt = BigInt(Double(self.amountFromBigInt) * Double(feePercentage) / 10000.0)
    let feeDisplay = feeBigInt.displayRate(decimals: self.from.decimals)
    return "Fee: \(feeDisplay) \(self.from.symbol) (\(feePercentage)% of \(self.amountFrom) \(self.from.symbol))"
  }

  var suggestBuyText: String {
    return "Buy 3000 KNC to discount 50% for 20 orders".toBeLocalised()
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)

    if let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: address), let ptToken = KNSupportedTokenStorage.shared.ptToken {
      self.from = ptToken
      self.to = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == destToken }) ?? self.eth
    } else {
      // not a promo wallet
      self.from = self.knc
      self.to = self.eth
    }

    self.amountFrom = ""
    self.amountTo = ""
    self.targetRate = ""

    self.balances = [:]
    self.balance = nil

    self.rateFromNode = nil
    self.updateProdCachedRate()
  }

  func updateWalletObject() {
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.walletObject.address) ?? self.walletObject
  }

  func updateFocusTextField(_ tag: Int) {
    self.focusTextFieldTag = tag
  }

  func swapTokens() {
    swap(&self.from, &self.to)
    self.amountFrom = ""
    self.amountTo = ""
    self.targetRate = ""
    self.balance = self.balances[self.from.contract]

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
    } else {
      self.to = token
    }
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
      self.rateFromNode = rate
      return true
    }
    return false
  }

  func updateRelatedOrders(_ orders: [KNOrderObject]) {
    self.relatedOrders = orders.filter({ return $0.state == .open }).sorted(by: { return $0.createdDate > $1.createdDate })
    self.cancelSuggestOrders = self.relatedOrders.filter({ return $0.targetPrice > self.targetRateDouble })
  }
}
