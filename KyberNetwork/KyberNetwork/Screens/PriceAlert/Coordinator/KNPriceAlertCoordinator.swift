// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result

class KNPriceAlertCoordinator: NSObject {

  static let shared: KNPriceAlertCoordinator = KNPriceAlertCoordinator()

  fileprivate var loadingTimer: Timer?

  func resume() {
    self.loadingTimer?.invalidate()
//    self.startLoadingListPriceAlerts(nil)
//    self.loadingTimer = Timer.scheduledTimer(
//      withTimeInterval: KNLoadingInterval.priceAlertLoadingInterval,
//      repeats: true,
//      block: { [weak self] timer in
//      self?.startLoadingListPriceAlerts(timer)
//    })
  }

  func pause() {
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  func startLoadingListPriceAlerts(_ sender: Any?) {
  }

  func loadListPriceAlerts(_ accessToken: String, completion: @escaping (Result<[KNAlertObject], AnyError>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion(.success(KNAlertStorage.shared.alerts))
    }
  }

  func addNewAlert(_ alert: KNAlertObject, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      KNAlertStorage.shared.addNewAlert(alert)
      completion(.success("Success"))
    }
  }

  func updateAlert(_ alert: KNAlertObject, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      KNAlertStorage.shared.updateAlert(alert)
      completion(.success("Success"))
    }
  }

  func removeAnAlert(_ alert: KNAlertObject, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      KNAlertStorage.shared.deleteAlert(alert)
      completion(.success("Success"))
    }
  }

  func updateUserSignedInPushTokenWithRetry() {
    //TODO: Send push token to server with retry on failure
  }
}
