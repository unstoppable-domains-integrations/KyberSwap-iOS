// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya

class KNLimitOrderServerCoordinator {

  static let shared = KNLimitOrderServerCoordinator()

  lazy var provider: MoyaProvider = {
    return MoyaProvider<LimitOrderService>(plugins: [MoyaCacheablePlugin()])
  }()

  func createNewOrder(accessToken: String, order: KNLimitOrder, signature: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion(.success(""))
    }
  }

  func getListOrders(accessToken: String, completion: @escaping (Result<[KNOrderObject], AnyError>) -> Void) {
    completion(.success([]))
  }

  func getNonce(accessToken: String, addr: String, src: String, dest: String, completion: @escaping (Result<Int, AnyError>) -> Void) {
    completion(.success(0))
  }

  func getFee(src: String, dest: String, srcAmount: Double, destAmount: Double, completion: @escaping (Result<Int, AnyError>) -> Void) {
    completion(.success(Int(arc4random() % 90 + 10)))
  }

  func cancelOrder(accessToken: String, orderID: Int, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion(.success(""))
    }
  }
}
