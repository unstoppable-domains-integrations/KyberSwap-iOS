// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya

// Manage fetching data from CoinMarketCap
// APIs: https://coinmarketcap.com/api/
class KNCoinTickerCoordinator {

  static let shared = KNCoinTickerCoordinator()
  private let provider: MoyaProvider = MoyaProvider<KNCoinMarketCapService>()

  private var coinTickers: [JSONDictionary] = []

  func fetchCoinTickers(limit: Int = 0, currency: String = "USD", completion: ((Result<[JSONDictionary], AnyError>) -> Void)?) {
    self.provider.request(.loadCoinTickers(limit: limit, currency: currency)) { [weak self] result in
      switch result {
      case .success(let resp):
        do {
          let jsonArr: [JSONDictionary] = try kn_cast(resp.mapJSON(failsOnEmptyData: false))
          self?.coinTickers = jsonArr
          completion?(.success(jsonArr))
        } catch let error {
          completion?(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion?(.failure(AnyError(error)))
      }
    }
  }

  func fetchCoinTicker(id: String, currency: String = "USD", completion: ((Result<JSONDictionary, AnyError>) -> Void)?) {
    self.provider.request(.loadCoinTicker(id: id, currency: currency)) { [weak self] result in
      switch result {
      case .success(let resp):
        do {
          let json: JSONDictionary = try kn_cast(resp.mapJSON(failsOnEmptyData: false))
          completion?(.success(json))
        } catch let error {
          completion?(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion?(.failure(AnyError(error)))
      }
    }
  }
}
