// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KWalletSortType {
  case nameAsc
  case nameDesc
  case balanceAsc
  case balanceDesc
}

enum KWalletCurrencyType: String {
  case usd = "USD"
  case eth = "ETH"
}

class KWalletBalanceViewModel: NSObject {

  private(set) var wallet: KNWalletObject
  private(set) var tokenObjects: [TokenObject] = []
  private(set) var tokensDisplayType: KWalletSortType = .nameAsc

  private(set) var trackerRateData: [String: KNTrackerRate] = [:]
  private(set) var displayedTokens: [TokenObject] = []
  private(set) var displayTrackerRates: [KNTrackerRate?] = []

  private(set) var currencyType: KWalletCurrencyType = .usd

  private(set) var balances: [String: Balance] = [:]
  private(set) var totalETHBalance: BigInt = BigInt(0)
  private(set) var totalUSDBalance: BigInt = BigInt(0)

  private(set) var searchText: String = ""

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
  var walletNameDisplayedText: String {
    return self.wallet.name
  }

  // MARK: Balance data
  func updateCurrencyType(_ type: KWalletCurrencyType) -> Bool {
    if self.currencyType == type { return false }
    self.currencyType = type
    return true
//    KNAppTracker.updateBalanceDisplayDataType(self.balanceDisplayType)
  }

  var balanceDisplayAttributedString: NSAttributedString {
    let value: String = {
      switch self.currencyType {
      case .usd:
        let usdValue = self.totalUSDBalance.shortString(units: .ether, maxFractionDigits: 2).prefix(11)
        return "\(usdValue)"
      case .eth:
        let ethValue = self.totalETHBalance.shortString(units: .ether, maxFractionDigits: 6).prefix(11)
        return "\(ethValue)"
      }
    }()
    let currency: String = self.currencyType.rawValue

    let valueAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 28),
      NSAttributedStringKey.foregroundColor: UIColor.white,
      NSAttributedStringKey.kern: 1.0,
    ]
    let currencyAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.white,
      NSAttributedStringKey.kern: 1.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: value, attributes: valueAttributes))
    attributedString.append(NSAttributedString(string: currency, attributes: currencyAttributes))
    return attributedString
  }

  var colorUSDButton: UIColor {
    if self.currencyType == .usd { return UIColor(red: 30, green: 137, blue: 193) }
    return UIColor(red: 29, green: 48, blue: 58)
  }

  var colorETHButton: UIColor {
    if self.currencyType == .eth { return UIColor(red: 30, green: 137, blue: 193) }
    return UIColor(red: 29, green: 48, blue: 58)
  }

  // MARK: Update display data
  func updateTokenDisplayType(nameClicked: Bool) {
    if nameClicked {
      if self.tokensDisplayType == .balanceAsc || self.tokensDisplayType == .balanceDesc {
        self.tokensDisplayType = .nameAsc
      } else {
        self.tokensDisplayType = self.tokensDisplayType == .nameAsc ? .nameDesc : .nameAsc
      }
    } else {
      if self.tokensDisplayType == .nameAsc || self.tokensDisplayType == .nameDesc {
        self.tokensDisplayType = .balanceAsc
      } else {
        self.tokensDisplayType = self.tokensDisplayType == .balanceAsc ? .balanceDesc : .balanceAsc
      }
    }
    self.createDisplayedData()
  }

  fileprivate func updateTokensDisplayType(_ type: KWalletSortType) -> Bool {
    if self.tokensDisplayType == type { return false }
    self.tokensDisplayType = type
    self.createDisplayedData()
    return true
  }

  func updateSearchText(_ text: String) {
    self.searchText = text
    self.createDisplayedData()
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
    let tokenObjects = self.tokenObjects.filter({ $0.contains(self.searchText) }).filter { token -> Bool in
      guard let balance = self.balances[token.contract] else { return false }
      return !balance.value.isZero
    }
    self.displayedTokens = {
      return tokenObjects.sorted(by: {
        return self.displayedTokenComparator(left: $0, right: $1)
      })
    }()
    self.displayTrackerRates = self.displayedTokens.map({
      return self.trackerRateData[$0.identifier()]
    })
  }

  fileprivate func displayedTokenComparator(left: TokenObject, right: TokenObject) -> Bool {
    if self.tokensDisplayType == .nameAsc { return left.symbol < right.symbol }
    if self.tokensDisplayType == .nameDesc { return left.symbol > right.symbol }
    guard let balance0 = self.balance(for: left) else { return false }
    guard let balance1 = self.balance(for: right) else { return true }
    // sort by balance holdings (number of coins)
    let value0 = balance0.value * BigInt(10).power(18 - left.decimals)
    let value1 = balance1.value * BigInt(10).power(18 - right.decimals)
    if self.tokensDisplayType == .balanceAsc { return value0 < value1 }
    return value0 > value1
  }
}
