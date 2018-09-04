// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KMarketsSortType {
  case nameAsc
  case nameDesc
  case priceAsc
  case priceDesc
  case changeAsc
  case changeDesc
}

class KMarketsViewModel: NSObject {

  private(set) var isKyberList: Bool = true
  private(set) var tokenObjects: [TokenObject] = []
  private(set) var displayType: KMarketsSortType = .changeDesc

  private(set) var trackerRateData: [String: KNTrackerRate] = [:]
  private(set) var displayedTokens: [TokenObject] = []
  private(set) var displayTrackerRates: [KNTrackerRate?] = []

  let currencyType: KWalletCurrencyType

  private(set) var searchText: String = ""

  init(currencyType: KWalletCurrencyType) {
    self.currencyType = currencyType
    super.init()
    self.setupTrackerRateData()
  }

  fileprivate func setupTrackerRateData() {
    KNTrackerRateStorage.shared.rates.forEach { rate in
      self.trackerRateData[rate.identifier] = rate
    }
  }

  var colorKyberListedButton: UIColor {
    if self.isKyberList { return KNAppStyleType.current.walletFlowHeaderColor }
    return UIColor(red: 29, green: 48, blue: 58)
  }

  var colorOthersButton: UIColor {
    if !self.isKyberList { return KNAppStyleType.current.walletFlowHeaderColor }
    return UIColor(red: 29, green: 48, blue: 58)
  }

  // MARK: Update display data
  // 1: Click name
  // 2: Click price
  // 3: Click change 24h
  func updateTokenDisplayType(positionClicked: Int) {
    if positionClicked == 1 {
      if self.displayType == .nameAsc || self.displayType == .nameDesc {
        self.displayType = self.displayType == .nameAsc ? .nameDesc : .nameAsc
      } else {
        self.displayType = .nameAsc
      }
    } else if positionClicked == 2 {
      if self.displayType == .priceAsc || self.displayType == .priceDesc {
        self.displayType = self.displayType == .priceAsc ? .priceDesc : .priceAsc
      } else {
        self.displayType = .priceAsc
      }
    } else {
      if self.displayType == .changeAsc || self.displayType == .changeDesc {
        self.displayType = self.displayType == .changeAsc ? .changeDesc : .changeAsc
      } else {
        self.displayType = .changeAsc
      }
    }
    self.createDisplayedData()
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

  // MARK: Update data
  // return true if data is updated and we need to update UIs
  // to reduce number of reloading collection view
  func updateTokenObjects(_ tokenObjects: [TokenObject]) -> Bool {
    if self.tokenObjects == tokenObjects { return false }
    self.tokenObjects = tokenObjects
    self.createDisplayedData()
    return true
  }

  func updateDisplayKyberList(_ isDisplayKyberList: Bool) {
    self.isKyberList = isDisplayKyberList
    self.createDisplayedData()
  }

  func exchangeRatesDataUpdated() {
    self.setupTrackerRateData()
    self.createDisplayedData()
  }

  fileprivate func createDisplayedData() {
    // Compute displayed token objects sorted by displayed type
    let tokenObjects = self.tokenObjects.filter({ $0.contains(self.searchText) }).filter({ $0.isSupported == self.isKyberList })
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
    // sort by name
    if self.displayType == .nameAsc { return left.symbol < right.symbol }
    if self.displayType == .nameDesc { return left.symbol > right.symbol }
    guard let tracker0 = self.trackerRateData[left.identifier()] else { return false }
    guard let tracker1 = self.trackerRateData[right.identifier()] else { return true }
    let change0: Double = {
      return self.currencyType == .eth ? tracker0.changeETH24h : tracker0.changeUSD24h
    }()
    let change1: Double = {
      return self.currencyType == .eth ? tracker1.changeETH24h : tracker1.changeUSD24h
    }()
    // sort by change 24h
    if self.displayType == .changeAsc { return change0 < change1 }
    if self.displayType == .changeDesc { return change0 > change1 }
    // sort by price, rate ETH or rate USD are the same to compare
    if self.displayType == .priceAsc { return tracker0.rateETHNow < tracker1.rateETHNow }
    return tracker0.rateETHNow > tracker1.rateETHNow
  }
}
