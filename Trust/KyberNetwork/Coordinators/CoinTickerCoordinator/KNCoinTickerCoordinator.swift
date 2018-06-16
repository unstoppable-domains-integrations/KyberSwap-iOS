// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya

// Manage fetching data from CoinMarketCap
// APIs: https://coinmarketcap.com/api/
class KNCoinTickerCoordinator {

  static let shared = KNCoinTickerCoordinator()
  private let provider: MoyaProvider = MoyaProvider<KNCoinMarketCapService>()
  fileprivate var allCoinTickersTimer: Timer?
  fileprivate var isLoadingAllCoinTickers: Bool = false
  fileprivate var lastUpdate: Date?

  func start() {
    self.startLoadingAllCoinTickers()
  }

  func stop() {
    self.stopLoadingAllCoinTickers()
  }

  fileprivate func startLoadingAllCoinTickers() {
    self.allCoinTickersTimer?.invalidate()
    // Immediately fetch when it is started
    if self.lastUpdate == nil || Date().timeIntervalSince(self.lastUpdate!) >= KNLoadingInterval.loadingCoinTickerInterval {
      self.isLoadingAllCoinTickers = true
      self.fetchCoinTickers { [weak self] _ in
        self?.lastUpdate = Date()
        self?.isLoadingAllCoinTickers = false
      }
    }
    self.allCoinTickersTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.loadingCoinTickerInterval,
      repeats: true,
      block: { [weak self] _ in
      if self?.isLoadingAllCoinTickers == false {
        self?.isLoadingAllCoinTickers = true
        self?.fetchCoinTickers(completion: { _ in
          self?.lastUpdate = Date()
          self?.isLoadingAllCoinTickers = false
        })
      }
    })
  }

  fileprivate func stopLoadingAllCoinTickers() {
    self.isLoadingAllCoinTickers = false
    self.allCoinTickersTimer?.invalidate()
    self.allCoinTickersTimer = nil
  }

  // inital fetch until it is success for the first time
  fileprivate func initialFetchAllCoinTickers() {
    self.fetchCoinTickers(limit: 500) { [weak self] result in
      if case .failure = result {
        let timeOut = DispatchTime.now() + KNLoadingInterval.defaultLoadingInterval
        DispatchQueue.main.asyncAfter(deadline: timeOut, execute: {
          self?.initialFetchAllCoinTickers()
        })
      }
    }
  }

  fileprivate  func fetchCoinTickers(limit: Int = 0, currency: String = "USD", completion: ((Result<[KNCoinTicker], AnyError>) -> Void)?) {
    print("---- Coin Tickers: Fetching limit: \(limit), currency: \(currency) ----")
    self.provider.request(.loadCoinTickers(limit: limit, currency: currency)) { [weak self] result in
      guard let `self` = self else { return }
      if self.isLoadingAllCoinTickers == false { return }
      switch result {
      case .success(let resp):
        do {
          let jsonArr: [JSONDictionary] = try resp.mapJSON(failsOnEmptyData: false) as? [JSONDictionary] ?? []
          let coinTickers = jsonArr.map({ KNCoinTicker(dict: $0, currency: currency) })
          var supportedTickers: [KNCoinTicker] = []
          KNSupportedTokenStorage.shared.supportedTokens.forEach({ token in
            if let coinTicker = coinTickers.first(where: { $0.isData(for: token) }) {
              supportedTickers.append(coinTicker)
            }
          })
          KNCoinTickerStorage.shared.update(coinTickers: supportedTickers)
          KNNotificationUtil.postNotification(for: kCoinTickersDidUpdateNotificationKey)
          print("---- Coin Tickers: Successful limit: \(limit), currency: \(currency) ----")
          completion?(.success(coinTickers))
        } catch let error {
          completion?(.failure(AnyError(error)))
        }
      case .failure(let error):
        print("---- Coin Tickers: Fetch error: \(error.prettyError) ----")
        completion?(.failure(AnyError(error)))
      }
    }
  }

  fileprivate  func fetchCoinTicker(id: String, currency: String = "USD", completion: ((Result<KNCoinTicker, AnyError>) -> Void)?) {
    self.provider.request(.loadCoinTicker(id: id, currency: currency)) { [weak self] result in
      guard let _ = `self` else { return }
      switch result {
      case .success(let resp):
        do {
          let json: JSONDictionary = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let coinTicker: KNCoinTicker = KNCoinTicker(dict: json, currency: currency)
          KNCoinTickerStorage.shared.update(coinTickers: [coinTicker])
          KNNotificationUtil.postNotification(for: kCoinTickersDidUpdateNotificationKey)
          completion?(.success(coinTicker))
        } catch let error {
          completion?(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion?(.failure(AnyError(error)))
      }
    }
  }
}
