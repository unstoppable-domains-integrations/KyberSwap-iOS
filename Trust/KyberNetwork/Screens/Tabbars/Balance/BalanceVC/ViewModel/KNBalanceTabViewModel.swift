// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KNTokensDisplayType: String {
  case change24h = "24h Change"
  case balanceValue = "Balance Value"
  case balanceHolding = "Balance Holdings"
  case kyberListed = "Kyber Listed"
  case kyberNotListed = "Kyner Not Listed"

  var buttonDisplayText: String {
    switch self {
    case .change24h: return "24 Chg%"
    case .balanceValue: return "Value"
    case .balanceHolding: return "Holdings"
    case .kyberListed: return "Listed"
    case .kyberNotListed: return "Not Listed"
    }
  }
}

enum KNBalanceDisplayDataType: String {
  case usd = "USD"
  case eth = "ETH"
}

class KNBalanceTabViewModel: NSObject {

  private(set) var wallet: KNWalletObject
  private(set) var tokenObjects: [TokenObject] = []
  private(set) var tokensDisplayType: KNTokensDisplayType = KNAppTracker.getTokenListDisplayDataType()

  private(set) var trackerRateData: [String: KNTrackerRate] = [:]
  private(set) var displayedTokens: [TokenObject] = []
  private(set) var displayTrackerRates: [KNTrackerRate?] = []

  private(set) var balanceDisplayType: KNBalanceDisplayDataType = KNAppTracker.getBalanceDisplayDataType()
  private(set) var balances: [String: Balance] = [:]
  private(set) var totalETHBalance: BigInt = BigInt(0)
  private(set) var totalUSDBalance: BigInt = BigInt(0)

 var expandedToken: String = ""

  init(wallet: KNWalletObject) {
    self.wallet = wallet
    super.init()
  }

  fileprivate func setupTrackerRateData() {
    KNTrackerRateStorage.shared.rates.forEach { rate in
      self.trackerRateData[rate.identifier] = rate
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
      let usdValue = self.totalUSDBalance.shortString(units: .ether, maxFractionDigits: 2).prefix(11)
      return "\(usdValue) USD"
    case .eth:
      let ethValue = self.totalETHBalance.shortString(units: .ether, maxFractionDigits: 6).prefix(11)
      return "\(ethValue) ETH"
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
    return self.tokensDisplayType.buttonDisplayText
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

  func trackerRate(for row: Int) -> KNTrackerRate? {
    return self.displayTrackerRates[row]
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

  func updateWalletObject(_ walletObject: KNWalletObject) {
    self.wallet = walletObject
  }

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

  func exchangeRatesDataUpdated() {
    self.setupTrackerRateData()
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
    self.displayTrackerRates = self.displayedTokens.map({
      return self.trackerRateData[$0.identifier()]
    })
  }

  // Either display by 24h change, balance value, or balance holding
  fileprivate func displayedTokenComparator(left: TokenObject, right: TokenObject) -> Bool {
    guard let balance0 = self.balance(for: left) else { return false }
    guard let balance1 = self.balance(for: right) else { return true }
    // sort by balance holdings (number of coins)
    if self.tokensDisplayType == .balanceHolding {
      return balance0.value > balance1.value
    }
    // display by change 24h or balance value in USD
    guard let trackerRate0 = self.trackerRateData[left.identifier()] else { return false }
    guard let trackerRate1 = self.trackerRateData[right.identifier()] else { return true }
    if self.tokensDisplayType == .change24h {
      // sort by 24h change
      let change24h0 = self.balanceDisplayType == .eth ? trackerRate0.changeETH24h : trackerRate0.changeUSD24h
      let change24h1 = self.balanceDisplayType == .eth ? trackerRate1.changeETH24h : trackerRate1.changeUSD24h
      return change24h0 > change24h1
    } else {
      // sort by balance in USD
      let rate0 = KNRate.rateUSD(from: trackerRate0)
      let rate1 = KNRate.rateUSD(from: trackerRate1)
      return rate0.rate * balance0.value > rate1.rate * balance1.value
    }
  }
}
