// Copyright SIX DAY LLC. All rights reserved.

import NotificationCenter

// Transaction Keys
let kTransactionDidUpdateNotificationKey = "kTransactionDidUpdateNotificationKey"
let kTransactionListDidUpdateNotificationKey = "kTransactionListDidUpdateNotificationKey"

// Token Transaction Key
let kTokenTransactionListDidUpdateNotificationKey = "kTokenTransactionListDidUpdateNotificationKey"
let kTokenObjectListDidUpdateNotificationKey = "kTokenObjectListDidUpdateNotificationKey"

// Balance Keys
let kETHBalanceDidUpdateNotificationKey = "kETHBalanceDidUpdateNotificationKey"
let kOtherBalanceDidUpdateNotificationKey = "kOtherBalanceDidUpdateNotificationKey"

// Rate
let kExchangeTokenRateNotificationKey = "kExchangeTokenRateNotificationKey"
let kExchangeUSDRateNotificationKey = "kExchangeUSDRateNotificationKey"

class KNNotificationUtil {

  static func postNotification(for key: String, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
    let notificationName = Notification.Name(rawValue: key)
    NotificationCenter.default.post(name: notificationName, object: object, userInfo: userInfo)
  }

  static func notificationName(from name: String) -> Notification.Name {
    return Notification.Name(name)
  }
}
