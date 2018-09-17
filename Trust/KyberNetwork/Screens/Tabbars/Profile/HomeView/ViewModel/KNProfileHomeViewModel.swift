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
          completion(.success(values))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}
