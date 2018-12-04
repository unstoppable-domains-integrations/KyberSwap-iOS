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

  fileprivate let provider = MoyaProvider<KNTrackerService>()

  fileprivate var cacheRates: [KNRate] = []
  fileprivate var cacheRateTimer: Timer?

  fileprivate var exchangeTokenRatesTimer: Timer?
  fileprivate var isLoadingExchangeTokenRates: Bool = false

  func getRate(from: TokenObject, to: TokenObject) -> KNRate? {
    if let rate = self.cacheRates.first(where: { $0.source == from.symbol && $0.dest == to.symbol }) { return rate }
    if from.isETH {
      if let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: to) {
        return KNRate(
          source: from.symbol,
          dest: to.symbol,
          rate: trackerRate.rateETHNow == 0.0 ? 0.0 : 1.0 / trackerRate.rateETHNow,
          decimals: to.decimals
        )
      }
    } else if to.isETH {
      if let rate = KNTrackerRateStorage.shared.trackerRate(for: from) {
        return KNRate.rateETH(from: rate)
      }
    }
    guard let rateFrom = KNTrackerRateStorage.shared.trackerRate(for: from),
      let rateTo = KNTrackerRateStorage.shared.trackerRate(for: to) else { return nil }
    if rateTo.rateUSDNow == 0.0 { return nil }
    return KNRate(
      source: from.symbol,
      dest: to.symbol,
      rate: rateFrom.rateUSDNow / rateTo.rateUSDNow,
      decimals: to.decimals
    )
  }

  func getCacheRate(from: String, to: String) -> KNRate? {
    if let rate = self.cacheRates.first(where: { $0.source == from && $0.dest == to }) { return rate }
    return nil
  }

  func usdRate(for token: TokenObject) -> KNRate? {
    if let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: token) {
      return KNRate.rateUSD(from: trackerRate)
    }
    return nil
  }

  func ethRate(for token: TokenObject) -> KNRate? {
    if let rate = self.getCacheRate(from: token.symbol, to: "ETH") { return rate }
    if let rate = KNTrackerRateStorage.shared.trackerRate(for: token) {
      return KNRate(source: "", dest: "", rate: rate.rateETHNow, decimals: 18)
    }
    return nil
  }

  init() {}

  func resume() {
    self.fetchCacheRate(nil)
    self.cacheRateTimer?.invalidate()
    self.cacheRateTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.cacheRateLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
        self?.fetchCacheRate(timer)
      }
    )
    // Immediate fetch data from server, then run timers with interview 60 seconds
    self.fetchExchangeTokenRate(nil)
    self.exchangeTokenRatesTimer?.invalidate()

    self.exchangeTokenRatesTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.cacheRateLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
      self?.fetchExchangeTokenRate(timer)
      }
    )
  }

  func pause() {
    self.cacheRateTimer?.invalidate()
    self.cacheRateTimer = nil
    self.exchangeTokenRatesTimer?.invalidate()
    self.exchangeTokenRatesTimer = nil
    self.isLoadingExchangeTokenRates = false
  }

  @objc func fetchExchangeTokenRate(_ sender: Any?) {
    if isLoadingExchangeTokenRates { return }
    isLoadingExchangeTokenRates = true
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KNTrackerService>()
      provider.request(.getRates, completion: { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.isLoadingExchangeTokenRates = false
          if case .success(let resp) = result {
            do {
              guard let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary else { return }
              var rates: [KNTrackerRate] = []
              for value in json.values {
                if let rateJSON = value as? JSONDictionary {
                  rates.append(KNTrackerRate(dict: rateJSON))
                }
              }
              KNTrackerRateStorage.shared.update(rates: rates)
              KNNotificationUtil.postNotification(for: kExchangeTokenRateNotificationKey)
            } catch {}
          }
        }
      })
    }
  }

  @objc func fetchCacheRate(_ sender: Any?) {
    KNInternalProvider.shared.getKNExchangeTokenRate { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let rates) = result {
        self.cacheRates = rates
      }
    }
  }
}
