// Copyright SIX DAY LLC. All rights reserved.

import Moya
import Result

class KNInternalProvider {

  static let shared = KNInternalProvider()

  let provider = MoyaProvider<KyberNetworkService>()

  // MARK: Gas
  func getKNCachedMaxGasPrice(completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    self.performFetchRequest(service: .getMaxGasPrice, completion: completion)
  }

  func getKNCachedGasPrice(completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    self.performFetchRequest(service: .getGasPrice, completion: completion)
  }

  // MARK: Rate
  func getKNExchangeTokenRate(completion: @escaping (Result<[KNRate], AnyError>) -> Void) {
    self.performFetchRequest(service: .getRate) { result in
      switch result {
      case .success(let object):
        do {
          let jsonArr: [JSONDictionary] = try kn_cast(object["data"])
          if isDebug { print("Load KN exchange rates successfully: \(jsonArr)") }
          let rates = try jsonArr.map({ return try KNRate(dictionary: $0) })
          completion(.success(rates))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getKNExchangeRateUSD(completion: @escaping (Result<[KNRate], AnyError>) -> Void) {
    self.performFetchRequest(service: .getRateUSD) { (result) in
      switch result {
      case .success(let object):
        do {
          let jsonArr: [JSONDictionary] = try kn_cast(object["data"])
          if isDebug { print("Load KN USD exchange rates successfully: \(jsonArr)") }
          let rates = try jsonArr.map({ return try KNRate(dictionary: $0, isUSDRate: true) })
          completion(.success(rates))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: History trade
  func getKNRecentTrades(completion: @escaping (Result<[KNTransaction], AnyError>) -> Void) {
    self.performFetchRequest(service: .getHistoryOneColumn) { (result) in
      switch result {
      case .success(let json):
        do {
          if isDebug { print("Load recent trades successfully: \(json)") }
          let jsonArray: [JSONDictionary] = try kn_cast(json["data"])
          let transactions = try jsonArray.map({ return try KNTransaction(dictionary: $0) })
          completion(.success(transactions))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: Latest block
  func getKNLatestBlock(completion: @escaping (Result<String, AnyError>) -> Void) {
    self.performFetchRequest(service: .getLatestBlock) { (result) in
      switch result {
      case .success(let json):
        do {
          if isDebug { print("Load recent trades successfully: \(json)") }
          let latestBlock: String = try kn_cast(json["data"])
          completion(.success(latestBlock))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getKNEnabled(completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.performFetchRequest(service: .getKyberEnabled) { (result) in
      switch result {
      case .success(let json):
        do {
          if isDebug { print("Load recent trades successfully: \(json)") }
          let isEnabled: Bool = try kn_cast(json["data"])
          completion(.success(isEnabled))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  private func performFetchRequest(service: KyberNetworkService, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    self.provider.request(service) { (result) in
      switch result {
      case .success(let response):
        do {
          _ = try response.filterSuccessfulStatusCodes()
          let json: JSONDictionary = try kn_cast(response.mapJSON())
          completion(.success(json))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}
