// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya
import BigInt

class KNLimitOrderServerCoordinator {

  static let shared = KNLimitOrderServerCoordinator()

  lazy var provider: MoyaProvider = {
    return MoyaProvider<LimitOrderService>(plugins: [MoyaCacheablePlugin()])
  }()

  fileprivate var loadingTimer: Timer?
  fileprivate(set) var orders: [KNOrderObject] = []

  func resume() {
    self.loadingTimer?.invalidate()
    self.startLoadingListOrders(nil)
    self.loadingTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.limitOrderLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
        self?.startLoadingListOrders(nil)
      }
    )
  }

  func pause() {
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  func startLoadingListOrders(_ sender: Any?) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    self.getListOrders(accessToken: accessToken) { [weak self] result in
      guard let _ = self else { return }
      if case .success = result {
        KNNotificationUtil.postNotification(for: kUpdateListOrdersNotificationKey)
      }
    }
  }

  func createNewOrder(accessToken: String, order: KNLimitOrder, signature: Data, completion: @escaping (Result<(KNOrderObject?, String?), AnyError>) -> Void) {
    self.provider.request(.createOrder(accessToken: accessToken, order: order, signedData: signature)) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let success = json["success"] as? Bool ?? false
          let message = json["message"] as? String ?? "Something went wrong, please try again later".toBeLocalised()
          if success {
            let object = KNOrderObject(json: json)
            self?.startLoadingListOrders(nil)
            completion(.success((object, nil)))
          } else {
            completion(.success((nil, message)))
          }
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getListOrders(accessToken: String, completion: @escaping (Result<[KNOrderObject], AnyError>) -> Void) {
    self.provider.request(.getOrders(accessToken: accessToken)) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let jsonArr = json["orders"] as? [JSONDictionary] ?? []
          let objects = jsonArr.map({ return KNOrderObject(json: $0) })
          self.orders = objects
          completion(.success(objects))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getNonce(accessToken: String, completion: @escaping (Result<(String, String), AnyError>) -> Void) {
    self.provider.request(.getNonce(accessToken: accessToken)) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          if let nonce = json["nonce"] as? String {
            completion(.success((nonce, "")))
          } else {
            let message = json["message"] as? String ?? "Something went wrong, please try again later".toBeLocalised()
            completion(.success(("", message)))
          }
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getFee(address: String, src: String, dest: String, srcAmount: Double, destAmount: Double, completion: @escaping (Result<(Double, String?), AnyError>) -> Void) {
    self.provider.request(.getFee(address: address, src: src, dest: dest, srcAmount: srcAmount, destAmount: destAmount)) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let fee = json["fee"] as? Double ?? 0.0
          let success = json["success"] as? Bool ?? false
          if success {
            completion(.success((fee, nil)))
          } else {
            let message = json["message"] as? String ?? "Something went wrong, please try again later".toBeLocalised()
            completion(.success((0, message)))
          }
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func cancelOrder(accessToken: String, orderID: Int, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.provider.request(.cancelOrder(accessToken: accessToken, id: "\(orderID)")) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let isCancelled = json["cancelled"] as? Bool ?? false
          if isCancelled {
            completion(.success("Your order has been cancelled".toBeLocalised()))
            self?.startLoadingListOrders(nil)
          } else {
            completion(.success(json["message"] as? String ?? "Something went wrong, please try again later".toBeLocalised()))
          }
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}
