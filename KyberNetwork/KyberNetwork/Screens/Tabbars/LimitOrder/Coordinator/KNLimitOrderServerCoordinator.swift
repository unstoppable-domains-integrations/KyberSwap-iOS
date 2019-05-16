// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result

class KNLimitOrderServerCoordinator {

  static let shared = KNLimitOrderServerCoordinator()

  func createNewOrder(accessToken: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion(.success(""))
    }
  }

  func cancelOrder(accessToken: String, orderID: Int, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion(.success(""))
    }
  }
}
