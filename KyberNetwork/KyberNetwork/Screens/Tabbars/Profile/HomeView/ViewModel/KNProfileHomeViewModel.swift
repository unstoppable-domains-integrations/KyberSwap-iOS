// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya

class KNProfileHomeViewModel: NSObject {

  var currentUser: IEOUser? { return IEOUserStorage.shared.user }
  var isUserSignedIn: Bool { return self.currentUser != nil }

  var wallets: [(String, String)] = []

  func getUserWallets(completion: @escaping (Result<[(String, String)], AnyError>) -> Void) {
    guard let accessToken = self.currentUser?.accessToken else {
      completion(.success([]))
      return
    }
    let provider = MoyaProvider<ProfileKYCService>()
    provider.request(.userWallets(accessToken: accessToken)) { result in
      switch result {
      case .success(let resp):
        do {
          _ = try resp.filterSuccessfulStatusCodes()
          let json: JSONDictionary = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let dataArr = json["data"] as? [JSONDictionary] ?? []
          let values = dataArr.map({ ($0["label"] as? String ?? "", $0["address"] as? String ?? "") })
          self.wallets = values
          let contacts = self.wallets.map({ return KNContact(address: $0.1, name: $0.0) })
          KNContactStorage.shared.update(contacts: contacts)
          KNNotificationUtil.postNotification(
            for: kUserWalletsListUpdatedNotificationKey,
            object: self.wallets,
            userInfo: nil
          )
          completion(.success(values))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func addWallet(label: String, address: String, completion: @escaping (Result<(Bool, String), AnyError>) -> Void) {
    guard let accessToken = self.currentUser?.accessToken else {
      completion(.success((false, NSLocalizedString("can.not.find.your.user", value: "Can not find your user", comment: ""))))
      return
    }
    let provider = MoyaProvider<ProfileKYCService>()
    provider.request(.addWallet(accessToken: accessToken, label: label, address: address)) { result in
      switch result {
      case .success(let resp):
        do {
          _ = try resp.filterSuccessfulStatusCodes()
          let json: JSONDictionary = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let isAdded: Bool = json["success"] as? Bool ?? false
          let message: String = {
            if isAdded { return json["message"] as? String ?? "" }
            let reasons: [String] = json["reason"] as? [String] ?? []
            return reasons.isEmpty ? "Unknown error" : reasons[0]
          }()
          completion(.success((isAdded, message)))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}
