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

enum KNBalanceDisplayDataType {
  case usd
  case eth
}

class KNBalanceTabViewModel: NSObject {

  private(set) var wallet: KNWalletObject
  private(set) var supportedTokens: [String: KNToken] = [:]
  private(set) var tokenObjects: [TokenObject] = []
  private(set) var coinTickers: [String: KNCoinTicker] = [:]

  private(set) var tokensDisplayType: KNTokensDisplayType = .change24h
  private(set) var displayedTokens: [TokenObject] = []
  private(set) var displayedCoinTickers: [KNCoinTicker?] = []

  private(set) var balanceDisplayType: KNBalanceDisplayDataType = .usd
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
    }
    KNJSONLoaderUtil.shared.tokens.forEach { self.supportedTokens[$0.address] = $0 }
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
    // TODO: Currently don't have icon name yet
    return self.wallet.icon
  }

  // MARK: Balance data
  func updateBalanceDisplayType() {
    self.balanceDisplayType = self.balanceDisplayType == .usd ? .eth : .usd
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
    return self.balances[token.contract]
  }

  func iconName(for token: TokenObject) -> String? {
    return self.supportedTokens[token.contract]?.icon
  }

  func isKyberListed(for token: TokenObject) -> Bool {
    return self.supportedTokens[token.contract] != nil
  }

  func expandedTokenIndex() -> Int? {
    return self.displayedTokens.index(where: { $0.contract == self.expandedToken })
  }

  // MARK: Update data
  // return true if data is updated and we need to update UIs
  // to reduce number of reloading collection view

  func updateTokenObjects(_ tokenObjects: [TokenObject]) -> Bool {
    if self.tokenObjects == tokenObjects {
      return false
    }
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
    let coinTickers = KNCoinTickerStorage.shared.coinTickers
    // Compute displayed token objects sorted by displayed type
    self.displayedTokens = {
      switch self.tokensDisplayType {
      case .change24h, .balanceValue, .balanceHolding:
        return self.tokenObjects.sorted(by: {
          return self.displayedTokenComparator(left: $0, right: $1)
        })
      case .kyberListed:
        return self.tokenObjects.filter { return self.supportedTokens[$0.contract] != nil }
      case .kyberNotListed:
        return self.tokenObjects.filter { return self.supportedTokens[$0.contract] == nil }
      }
    }()
    self.displayedCoinTickers = []

    self.displayedTokens.forEach { token in
      let coinTicker: KNCoinTicker? = {
        let tickers = coinTickers.filter { return $0.symbol == token.symbol }
        if tickers.count == 1 { return tickers[0] }
        return tickers.first(where: { $0.name.replacingOccurrences(of: " ", with: "").lowercased() == token.name.lowercased() })
      }()
      self.displayedCoinTickers.append(coinTicker)
    }
  }

  // Either display by 24h change, balance value, or balance holding
  fileprivate func displayedTokenComparator(left: TokenObject, right: TokenObject) -> Bool {
    let id0 = left.symbol + " " + left.name.replacingOccurrences(of: " ", with: "").lowercased()
    let id1 = right.symbol + " " + right.name.replacingOccurrences(of: " ", with: "").lowercased()
    guard let balance0 = self.balances[left.contract] else { return false }
    guard let balance1 = self.balances[right.contract] else { return true }
    // sort by balance holdings (number of coins)
    if self.tokensDisplayType == .balanceHolding {
      return balance0.value > balance1.value
    }
    // display by change 24h or balance value in USD
    guard let ticker0 = self.coinTickers[id0] else { return false }
    guard let ticker1 = self.coinTickers[id1] else { return true }
    if self.tokensDisplayType == .change24h {
      // sort by 24h change
      return Double(ticker0.percentChange24h)! > Double(ticker1.percentChange24h)!
    } else {
      // sort by balance in USD
      let rate0 = KNRate.rateUSD(from: ticker0)
      let rate1 = KNRate.rateUSD(from: ticker1)
      return rate0.rate * balance0.value > rate1.rate * balance1.value
    }
  }
}
