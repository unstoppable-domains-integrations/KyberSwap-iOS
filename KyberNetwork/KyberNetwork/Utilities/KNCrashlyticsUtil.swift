// Copyright SIX DAY LLC. All rights reserved.

import Crashlytics
import FirebaseAnalytics

class KNCrashlyticsUtil {

  static func logCustomEvent(withName name: String, customAttributes: [String: Any]?) {
    if !isDebug {
      Analytics.logEvent(name, parameters: customAttributes)
      Answers.logCustomEvent(withName: name, customAttributes: customAttributes)
    }
  }
}
