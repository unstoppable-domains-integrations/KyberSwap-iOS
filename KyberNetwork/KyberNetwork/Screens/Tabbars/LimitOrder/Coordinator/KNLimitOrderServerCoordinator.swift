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
          let message: String = {
            if let errors = json["message"] as? JSONDictionary, let key = errors.keys.first, let msg = (errors.values.first as? [String])?.first {
              return "\(key) \(msg)"
            }
            return "Something went wrong, please try again later".toBeLocalised()
          }()
          if success {
            let fields = json["fields"] as? [String] ?? []
            let dataArr = json["order"] as? [Any] ?? []
            let object = KNOrderObject(fields: fields, data: dataArr)
            KNLimitOrderStorage.shared.addNewOrder(object)
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
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          if let jsonArr = json["orders"] as? [[Any]], let fields = json["fields"] as? [String] {
            let objects = jsonArr.map({ return KNOrderObject(fields: fields, data: $0) })
            KNLimitOrderStorage.shared.updateOrdersFromServer(objects)
            completion(.success(objects))
          } else {
            completion(.success([]))
          }
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
            KNLimitOrderStorage.shared.updateOrderState(orderID, state: .cancelled)
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

  func checkEligibleAddress(accessToken: String, address: String, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.provider.request(.checkEligibleAddress(accessToken: accessToken, address: address)) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          completion(.success(json["eligible_address"] as? Bool ?? true))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getRelatedOrders(accessToken: String, address: String, src: String, dest: String, minRate: Double, completion: @escaping ((Result<[KNOrderObject], AnyError>) -> Void)) {
    let service = LimitOrderService.getRelatedOrders(accessToken: accessToken, address: address, src: src, dest: dest, rate: minRate)
    self.provider.request(service) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          if let jsonArr = json["orders"] as? [[Any]], let fields = json["fields"] as? [String] {
            let objects = jsonArr.map({ return KNOrderObject(fields: fields, data: $0) })
            KNLimitOrderStorage.shared.updateOrdersFromServer(objects)
            completion(.success(objects))
          } else {
            completion(.success([]))
          }
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getPendingBalances(accessToken: String, address: String, completion: @escaping ((Result<JSONDictionary, AnyError>) -> Void)) {
    self.provider.request(.pendingBalance(accessToken: accessToken, address: address)) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        do {
          let _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          completion(.success(json["data"] as? JSONDictionary ?? [:]))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}
