// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya

class KNPriceAlertCoordinator: NSObject {

  static let shared: KNPriceAlertCoordinator = KNPriceAlertCoordinator()
  let provider = MoyaProvider<UserInfoService>()

  fileprivate var loadingTimer: Timer?

  func resume() {
    self.loadingTimer?.invalidate()
    self.startLoadingListPriceAlerts(nil)
    self.loadingTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.priceAlertLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
        self?.startLoadingListPriceAlerts(timer)
      }
    )
  }

  func pause() {
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  func startLoadingListPriceAlerts(_ sender: Any?) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    self.loadListPriceAlerts(accessToken) { [weak self] result in
      guard let _ = self else { return }
      if case .success = result {
        KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
      }
    }
  }

  func loadListPriceAlerts(_ accessToken: String, completion: @escaping (Result<[KNAlertObject], AnyError>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getListAlerts(accessToken: accessToken)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let jsonArr = json["data"] as? [JSONDictionary] ?? []
              let alerts = jsonArr.map({ return KNAlertObject(json: $0) })
              KNAlertStorage.shared.updateAlerts(alerts)
              completion(.success(alerts))
            } catch let error {
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func addNewAlert(accessToken: String, alert: KNAlertObject, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.provider.request(.addNewAlert(accessToken: accessToken, alert: alert)) { [weak self] result in
      guard let _ = self else { return }
      DispatchQueue.main.async {
        switch result {
        case .success(let data):
          do {
            let _ = try data.filterSuccessfulStatusCodes()
            self?.startLoadingListPriceAlerts(nil)
            completion(.success(""))
          } catch let error {
            completion(.failure(AnyError(error)))
          }
        case .failure(let error):
          completion(.failure(AnyError(error)))
        }
      }
    }
  }

  func updateAlert(accessToken: String, alert: KNAlertObject, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.provider.request(.updateAlert(accessToken: accessToken, alert: alert)) { [weak self] result in
      guard let _ = self else { return }
      DispatchQueue.main.async {
        switch result {
        case .success(let data):
          do {
            let _ = try data.filterSuccessfulStatusCodes()
            KNAlertStorage.shared.updateAlert(alert)
            self?.startLoadingListPriceAlerts(nil)
            completion(.success(""))
          } catch let error {
            completion(.failure(AnyError(error)))
          }
        case .failure(let error):
          completion(.failure(AnyError(error)))
        }
      }
    }
  }

  func removeAnAlert(accessToken: String, alert: KNAlertObject, completion: @escaping (Result<String, AnyError>) -> Void) {
    let id = alert.id
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.removeAnAlert(accessToken: accessToken, alertID: id)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              KNAlertStorage.shared.deleteAlert(alert)
              self?.startLoadingListPriceAlerts(nil)
              completion(.success(""))
            } catch let error {
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func updateUserSignedInPushTokenWithRetry() {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken, let pushToken = KNAppTracker.getPushNotificationToken() else { return }
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.addPushToken(accessToken: accessToken, pushToken: pushToken)) { [weak self] result in
        DispatchQueue.main.async {
          if case .failure = result {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
              self?.updateUserSignedInPushTokenWithRetry()
            })
          }
        }
      }
    }
  }

  func getAlertMethods(accessToken: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getListAlertMethods(accessToken: accessToken)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
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
  }

  func updateAlertMethods(accessToken: String, email: Bool, telegram: Bool, pushNoti: Bool, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.setAlertMethods(accessToken: accessToken, email: email, telegram: telegram, pushNoti: pushNoti)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              completion(.success(""))
            } catch let error {
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }
}
