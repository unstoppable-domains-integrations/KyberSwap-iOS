// Copyright SIX DAY LLC. All rights reserved.

import Crashlytics

class KNCrashlyticsUtil {

  static func logCustomEvent(withName name: String, customAttributes: [String: Any]?) {
    if !isDebug {
      Answers.logCustomEvent(withName: name, customAttributes: customAttributes)
    }
  }
}
