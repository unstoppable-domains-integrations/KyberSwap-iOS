// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import Moya

/*

 This coordinator controls the fetching exchange token + usd rates,
 running timer interval to frequently fetch data from /getRate and /getRateUSD APIs

*/

class KNRateCoordinator {

  static let shared = KNRateCoordinator()

  fileprivate let provider = MoyaProvider<KyberNetworkService>()

  fileprivate var exchangeTokenRatesTimer: Timer?
  fileprivate var isLoadingExchangeTokenRates: Bool = false
  fileprivate(set) var tokenRates: [KNRate] = []

  fileprivate var exchangeUSDRatesTimer: Timer?
  fileprivate var isLoadingExchangeUSDRates: Bool = false
  fileprivate(set) var usdRates: [KNRate] = []

  func getRate(from: KNToken, to: KNToken) -> KNRate? {
    return self.tokenRates.first(where: { $0.source == from.symbol && $0.dest == to.symbol })
  }

  func usdRate(for token: KNToken) -> KNRate? {
    return self.usdRates.first(where: { $0.source == token.symbol })
  }

  init() {}

  func resume() {
    // Immediate fetch data from server, then run timers with interview 60 seconds
    self.fetchExchangeTokenRate(nil)
    self.exchangeTokenRatesTimer?.invalidate()

    self.exchangeTokenRatesTimer = Timer.scheduledTimer(
      timeInterval: KNLoadingInterval.defaultLoadingInterval,
      target: self,
      selector: #selector(self.fetchExchangeTokenRate(_:)),
      userInfo: nil,
      repeats: true
    )

    self.fetchExchangeUSDRates(nil)
    self.exchangeUSDRatesTimer?.invalidate()

    self.exchangeUSDRatesTimer = Timer.scheduledTimer(
      timeInterval: KNLoadingInterval.defaultLoadingInterval,
      target: self,
      selector: #selector(self.fetchExchangeUSDRates(_:)),
      userInfo: nil,
      repeats: true
    )
  }

  func pause() {
    self.exchangeTokenRatesTimer?.invalidate()
    self.exchangeTokenRatesTimer = nil
    self.isLoadingExchangeTokenRates = false

    self.exchangeUSDRatesTimer?.invalidate()
    self.exchangeUSDRatesTimer = nil
    self.isLoadingExchangeUSDRates = false
  }

  @objc func fetchExchangeTokenRate(_ sender: Any?) {
    if isLoadingExchangeTokenRates { return }
    isLoadingExchangeTokenRates = true
    KNInternalProvider.shared.getKNExchangeTokenRate { [weak self] (result) in
      guard let `self` = self else { return }
      self.isLoadingExchangeTokenRates = false
      if case .success(let rates) = result {
        self.tokenRates = rates
        KNNotificationUtil.postNotification(for: kExchangeTokenRateNotificationKey)
      }
    }
  }

  @objc func fetchExchangeUSDRates(_ sender: Any?) {
    if isLoadingExchangeUSDRates { return }
    isLoadingExchangeUSDRates = true
    KNInternalProvider.shared.getKNExchangeRateUSD { [weak self] (result) in
      guard let `self` = self else { return }
      self.isLoadingExchangeUSDRates = false
      if case .success(let rates) = result {
        self.usdRates = rates
        KNNotificationUtil.postNotification(for: kExchangeUSDRateNotificationKey)
      }
    }
  }
}
