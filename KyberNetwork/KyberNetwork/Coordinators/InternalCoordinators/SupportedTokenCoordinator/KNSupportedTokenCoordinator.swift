// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya

class KNSupportedTokenCoordinator {

  static let shared = KNSupportedTokenCoordinator()
  fileprivate let provider = MoyaProvider<KyberNetworkService>()

  fileprivate var timer: Timer?

  func resume() {
    self.fetchSupportedTokens()
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.loadingSupportedTokenInterval,
      repeats: true,
      block: { [weak self] _ in
      self?.fetchSupportedTokens()
      }
    )
  }

  func pause() {
    self.timer?.invalidate()
  }

  fileprivate func fetchSupportedTokens() {
    // Token address is different for other envs
    if KNEnvironment.default == .kovan {
      let tokens = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
      KNSupportedTokenStorage.shared.updateSupportedTokens(tokenObjects: tokens)
      return
    }
    KNSupportedTokenStorage.shared.addLocalSupportedTokens()
    print("---- Supported Tokens: Start fetching data ----")
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.supportedToken) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              let respJSON: JSONDictionary = try response.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let jsonArr: [JSONDictionary] = respJSON["data"] as? [JSONDictionary] ?? []
              let tokenObjects = jsonArr.map({ return TokenObject(apiDict: $0) })
              KNSupportedTokenStorage.shared.updateSupportedTokens(tokenObjects: tokenObjects)
              KNAppTracker.updateSuccessfullyLoadSupportedTokens()
              print("---- Supported Tokens: Load successfully")
            } catch let error {
              print("---- Supported Tokens: Cast reponse failed with error: \(error.prettyError) ----")
            }
          case .failure(let error):
            print("---- Supported Tokens: Failed with error: \(error.prettyError)")
          }
        }
      }
    }
  }
}
