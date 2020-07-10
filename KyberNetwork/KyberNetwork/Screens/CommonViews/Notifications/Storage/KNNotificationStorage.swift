// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

class KNNotificationStorage {
  static let shared: KNNotificationStorage = KNNotificationStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var notifications: [KNNotification] {
    if self.realm == nil { return [] }
    if self.realm.objects(KNNotification.self).isInvalidated { return [] }
    return self.realm.objects(KNNotification.self)
      .filter({ return $0.id != -1 })
  }

  func updateNotification(_ noti: KNNotification) {
    if self.realm == nil { return }
    if self.realm.objects(KNNotification.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.add([noti], update: .modified)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListNotificationsKey)
  }

  func updateNotificationsFromServer(_ notifications: [KNNotification]) {
    if self.realm == nil { return }
    if self.realm.objects(KNNotification.self).isInvalidated { return }
    self.realm.beginWrite()
    // filter removed alerts
    let notiIDs = notifications.map({ return $0.id })
    let removedNotis = self.notifications.filter({ return !notiIDs.contains($0.id) })
    self.realm.delete(removedNotis)
    self.realm.add(notifications, update: .modified)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListNotificationsKey)
  }

  func getObject(primaryKey: Int) -> KNNotification? {
    if self.realm == nil { return nil }
    if self.realm.objects(KNNotification.self).isInvalidated { return nil }
    return self.realm.object(ofType: KNNotification.self, forPrimaryKey: primaryKey)
  }

  func deleteAll() {
    if self.realm == nil { return }
    if self.realm.objects(KNNotification.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(self.notifications)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListNotificationsKey)
  }
}
