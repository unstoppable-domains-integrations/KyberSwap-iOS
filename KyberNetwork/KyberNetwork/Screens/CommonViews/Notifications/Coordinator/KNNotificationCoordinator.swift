// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya

class KNNotificationCoordinator: NSObject {

  static let shared: KNNotificationCoordinator = KNNotificationCoordinator()
  let provider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])

  fileprivate var loadingTimer: Timer?

  func resume() {
    self.loadingTimer?.invalidate()
    self.startLoadingNotifications(nil)
    self.loadingTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.notificationLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
        self?.startLoadingNotifications(timer)
      }
    )
  }

  func pause() {
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  func startLoadingNotifications(_ sender: Any?) {
    if KNWalletStorage.shared.wallets.isEmpty { return }
    self.loadListNotifications { [weak self] (notifications, error) in
      guard let _ = self else { return }
      if error == nil {
        KNNotificationStorage.shared.updateNotificationsFromServer(notifications)
      }
    }
  }

  func loadListNotifications(completion: @escaping ([KNNotification], String?) -> Void) {
    let accessToken = IEOUserStorage.shared.user?.accessToken
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getNotification(accessToken: accessToken)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              if let jsonArr = json["data"] as? [JSONDictionary] {
                let notifications = jsonArr.map({ return KNNotification(json: $0) })
                KNNotificationStorage.shared.updateNotificationsFromServer(notifications)
                completion(notifications, nil)
                return
              }
              let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
              completion([], message)
            } catch {
              completion([], NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion([], error.prettyError)
          }
        }
      }
    }
  }

  func markAsRead(ids: [Int], completion: @escaping (String?) -> Void) {
    if ids.isEmpty {
      completion(nil)
      return
    }
    let accessToken = IEOUserStorage.shared.user?.accessToken
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.markAsRead(accessToken: accessToken, ids: ids)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? false
              if success {
                self?.startLoadingNotifications(nil)
                completion(nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion(message)
              }
            } catch {
              completion(NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion(error.prettyError)
          }
        }
      }
    }
  }
}
