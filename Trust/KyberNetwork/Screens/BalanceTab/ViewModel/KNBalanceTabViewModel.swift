// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KNTokensDisplayType: String {
  case change24h = "24h Change"
  case balanceValue = "Balance Value"
  case balanceHolding = "Balance Holding"
  case kyberListed = "Kyber Listed"
  case kyberNotListed = "Not Listed by Kyber DEX"
}

enum KNBalanceDisplayDataType: String {
  case usd = "USD"
  case eth = "ETH"
}

class KNBalanceTabViewModel: NSObject {

  private(set) var wallet: KNWalletObject
  private(set) var tokenObjects: [TokenObject] = []
  // cointicker with key is symbol + name
  private(set) var coinTickers: [String: KNCoinTicker] = [:]
  // cointicker with key is symbol only (due to inconsistent between KN and CMC
  private(set) var symbolCoinTickers: [String: KNCoinTicker] = [:]
  // cointicker with key is name only (due to custom symbol name from KN supported token)
  private(set) var nameCoinTickers: [String: KNCoinTicker] = [:]

  private(set) var tokensDisplayType: KNTokensDisplayType = KNAppTracker.getTokenListDisplayDataType()
  private(set) var displayedTokens: [TokenObject] = []
  private(set) var displayedCoinTickers: [KNCoinTicker?] = []

  private(set) var balanceDisplayType: KNBalanceDisplayDataType = KNAppTracker.getBalanceDisplayDataType()
  private(set) var balances: [String: Balance] = [:]
  private(set) var totalETHBalance: BigInt = BigInt(0)
  private(set) var totalUSDBalance: BigInt = BigInt(0)

 var expandedToken: String = ""

  init(wallet: KNWalletObject) {
    self.wallet = wallet
    super.init()
    self.setupData()
  }

  private func setupData() {
    let coinTickers = KNCoinTickerStorage.shared.coinTickers
    coinTickers.forEach {
      let identifier = $0.symbol + " " + $0.name.replacingOccurrences(of: " ", with: "").lowercased()
      self.coinTickers[identifier] = $0
      self.symbolCoinTickers[$0.symbol] = $0
      self.nameCoinTickers[$0.name.replacingOccurrences(of: " ", with: "").lowercased()] = $0
    }
  }

  // MARK: Wallet data
  var walletAddressDisplayedText: String {
    let address = self.wallet.address
    return String(address.prefix(10)) + "......" + String(address.suffix(10))
  }

  var walletNameDisplayedText: String {
    return self.wallet.name
  }

  var walletIconName: String {
    return self.wallet.icon
  }

  // MARK: Balance data
  func updateBalanceDisplayType() {
    self.balanceDisplayType = self.balanceDisplayType == .usd ? .eth : .usd
    KNAppTracker.updateBalanceDisplayDataType(self.balanceDisplayType)
  }

  var balanceDisplayText: String {
    switch self.balanceDisplayType {
    case .usd:
      return "\(self.totalUSDBalance.shortString(units: .ether, maxFractionDigits: 2)) USD"
    case .eth:
      return "\(self.totalETHBalance.shortString(units: .ether)) ETH"
    }
  }

  // MARK: Button control
  func updateTokensDisplayType(_ type: String) -> Bool {
    if self.tokensDisplayType.rawValue == type { return false }
    self.tokensDisplayType = KNTokensDisplayType(rawValue: type) ?? .change24h
    KNAppTracker.updateTokenListDisplayDataType(self.tokensDisplayType)
    self.createDisplayedData()
    return true
  }

  var filterSortButtonTitle: String {
    return self.tokensDisplayType.rawValue
  }

  var listPickerData: [String] = {
    return [
      KNTokensDisplayType.change24h.rawValue,
      KNTokensDisplayType.balanceValue.rawValue,
      KNTokensDisplayType.balanceHolding.rawValue,
      KNTokensDisplayType.kyberListed.rawValue,
      KNTokensDisplayType.kyberNotListed.rawValue,
    ]
  }()

  var addTokenButtonTitle: String {
    return "Add Token".toBeLocalised()
  }

  // MARK: Tokens balance table view
  var numberRows: Int {
    return self.displayedTokens.count
  }

  func tokenObject(for row: Int) -> TokenObject {
    return self.displayedTokens[row]
  }

  func coinTicker(for row: Int) -> KNCoinTicker? {
    return self.displayedCoinTickers[row]
  }

  func balance(for token: TokenObject) -> Balance? {
    if let balance = self.balances[token.contract] { return balance }
    if let amount = token.value.shortBigInt(decimals: 0) {
      return Balance(value: amount)
    }
    return nil
  }

  func iconName(for token: TokenObject) -> String? {
    return token.icon
  }

  func expandedTokenIndex() -> Int? {
    return self.displayedTokens.index(where: { $0.contract == self.expandedToken })
  }

  // MARK: Update data
  // return true if data is updated and we need to update UIs
  // to reduce number of reloading collection view

  func updateTokenObjects(_ tokenObjects: [TokenObject]) -> Bool {
    if self.tokenObjects == tokenObjects { return false }
    self.tokenObjects = tokenObjects
    self.createDisplayedData()
    return true
  }

  func updateTokenBalances(_ balances: [String: Balance]) -> Bool {
    var isDataChanged: Bool = false
    balances.forEach {
      if self.balances[$0.key] == nil || self.balances[$0.key]!.value != $0.value.value {
        isDataChanged = true
      }
      self.balances[$0.key] = $0.value
    }
    if isDataChanged { self.createDisplayedData() }
    return isDataChanged
  }

  func updateBalanceInETHAndUSD(ethBalance: BigInt, usdBalance: BigInt) {
    self.totalETHBalance = ethBalance
    self.totalUSDBalance = usdBalance
  }

  func coinTickersDidUpdate() {
    self.setupData()
    self.createDisplayedData()
  }

  fileprivate func createDisplayedData() {
    // Compute displayed token objects sorted by displayed type
    self.displayedTokens = {
      switch self.tokensDisplayType {
      case .change24h, .balanceValue, .balanceHolding:
        return self.tokenObjects.sorted(by: {
          return self.displayedTokenComparator(left: $0, right: $1)
        })
      case .kyberListed:
        return self.tokenObjects.filter { return $0.isSupported }
      case .kyberNotListed:
        return self.tokenObjects.filter { return !$0.isSupported }
      }
    }()
    self.displayedCoinTickers = self.displayedTokens.map({
      let name = $0.name.replacingOccurrences(of: " ", with: "").lowercased()
      let coinTicker = self.coinTickers[$0.symbolAndNameID] ?? self.nameCoinTickers[name] ?? self.symbolCoinTickers[$0.symbol]
      return coinTicker
    })
  }

  // Either display by 24h change, balance value, or balance holding
  fileprivate func displayedTokenComparator(left: TokenObject, right: TokenObject) -> Bool {
    let name0 = left.name.replacingOccurrences(of: " ", with: "").lowercased()
    let name1 = right.name.replacingOccurrences(of: " ", with: "").lowercased()
    let id0 = left.symbol + " " + name0
    let id1 = right.symbol + " " + name1
    guard let balance0 = self.balances[left.contract] else { return false }
    guard let balance1 = self.balances[right.contract] else { return true }
    // sort by balance holdings (number of coins)
    if self.tokensDisplayType == .balanceHolding {
      return balance0.value > balance1.value
    }
    // display by change 24h or balance value in USD
    guard let ticker0 = self.coinTickers[id0] ?? self.nameCoinTickers[name0] ?? self.symbolCoinTickers[left.symbol] else { return false }
    guard let ticker1 = self.coinTickers[id1] ?? self.nameCoinTickers[name1] ?? self.symbolCoinTickers[right.symbol] else { return true }
    if self.tokensDisplayType == .change24h {
      // sort by 24h change
      guard let double0 = Double(ticker0.percentChange24h) else { return false }
      guard let double1 = Double(ticker1.percentChange24h) else { return true }
      return double0 > double1
    } else {
      // sort by balance in USD
      let rate0 = KNRate.rateUSD(from: ticker0)
      let rate1 = KNRate.rateUSD(from: ticker1)
      return rate0.rate * balance0.value > rate1.rate * balance1.value
    }
  }
}
