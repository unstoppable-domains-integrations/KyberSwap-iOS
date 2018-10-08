// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya

class KNSupportedTokenCoordinator {

  static let shared = KNSupportedTokenCoordinator()
  fileprivate let provider = MoyaProvider<KNTrackerService>()

  fileprivate var timer: Timer?

  func resume() {
    let needReload: Bool = {
      if let date = KNAppTracker.getSuccessfullyLoadSupportedTokensDate(), Date().timeIntervalSince(date) <= KNLoadingInterval.loadingSupportedTokenInterval / 2.0 {
        return false
      }
      return true
    }()
    if needReload { self.fetchTrackerSupportedTokens() }
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.loadingSupportedTokenInterval,
      repeats: true,
      block: { [weak self] _ in
      self?.fetchTrackerSupportedTokens()
      }
    )
  }

  func pause() {
    self.timer?.invalidate()
  }

  fileprivate func fetchTrackerSupportedTokens() {
    // Tracker is not supported for other environment
    if KNEnvironment.default != .mainnetTest && KNEnvironment.default != .production { return }
    print("---- Supported Tokens: Start fetching data ----")
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getSupportedTokens()) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              let jsonArr: [JSONDictionary] = try response.mapJSON(failsOnEmptyData: false) as? [JSONDictionary] ?? []
              let tokenObjects = jsonArr.map({ return TokenObject(trackerDict: $0) })
              KNSupportedTokenStorage.shared.updateFromTracker(tokenObjects: tokenObjects)
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
