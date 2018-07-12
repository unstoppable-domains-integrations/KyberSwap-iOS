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

  fileprivate var exchangeTokenRatesTimer: Timer?
  fileprivate var isLoadingExchangeTokenRates: Bool = false

  func getRate(from: TokenObject, to: TokenObject) -> KNRate? {
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

  func usdRate(for token: TokenObject) -> KNRate? {
    if let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: token) {
      return KNRate.rateUSD(from: trackerRate)
    }
    return nil
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
  }

  func pause() {
    self.exchangeTokenRatesTimer?.invalidate()
    self.exchangeTokenRatesTimer = nil
    self.isLoadingExchangeTokenRates = false
  }

  @objc func fetchExchangeTokenRate(_ sender: Any?) {
    if isLoadingExchangeTokenRates { return }
    isLoadingExchangeTokenRates = true
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KNTrackerService>()
      provider.request(.getRates(), completion: { [weak self] result in
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
}
