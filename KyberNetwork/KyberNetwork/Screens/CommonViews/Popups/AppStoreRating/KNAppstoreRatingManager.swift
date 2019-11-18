// Copyright SIX DAY LLC. All rights reserved.

import StoreKit

enum KNAppstoreRatingManager {
  static let kLastTimePromptedRatingKey = "kLastTimePromptedRatingKey"
  static let kLastVersionPromptedForReviewKey = "kLastVersionPromptedForReviewKey"

  @available(iOS 10.3, *)
  static func requestReviewIfAppropriate() {
    let lastTimePrompted: Double = UserDefaults.standard.object(forKey: kLastTimePromptedRatingKey) as? Double ?? 0.0
    let interval = KNEnvironment.default.isMainnet ? 4.0 * 30.0 * 24.0 * 60.0 * 60.0 : 60.0 // every 4 months
    if Date().timeIntervalSince1970 < lastTimePrompted + interval { return } // not show again for 2 days

    let infoDictionaryKey = kCFBundleVersionKey as String
    guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
        else {
      fatalError("Expected to find a bundle version in the info dictionary")
    }

    let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: kLastVersionPromptedForReviewKey)

    // only check version for mainnet
    if currentVersion != lastVersionPromptedForReview || !KNEnvironment.default.isMainnet {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        SKStoreReviewController.requestReview()
        UserDefaults.standard.set(currentVersion, forKey: kLastVersionPromptedForReviewKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: kLastTimePromptedRatingKey)
      }
    }
  }
}
