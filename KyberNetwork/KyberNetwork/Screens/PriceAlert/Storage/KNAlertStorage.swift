// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

class KNAlertStorage {
  static let shared: KNAlertStorage = KNAlertStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var alerts: [KNAlertObject] {
    if self.realm == nil { return [] }
    return self.realm.objects(KNAlertObject.self)
      .filter({ return $0.id != -1 })
  }

  func addNewAlert(_ alert: KNAlertObject) {
    self.addNewAlerts([alert])
  }

  func addNewAlerts(_ alerts: [KNAlertObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.add(alerts, update: false)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }

  func updateAlert(_ alert: KNAlertObject) {
    self.updateAlerts([alert])
  }

  func updateAlerts(_ alerts: [KNAlertObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.add(alerts, update: true)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }

  func deleteAlert(_ alert: KNAlertObject) {
    self.deleteAlerts([alert])
  }

  func deleteAlerts(_ alerts: [KNAlertObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.delete(alerts)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }
  func getObject(primaryKey: Int) -> KNAlertObject? {
    if self.realm == nil { return nil }
    return self.realm.object(ofType: KNAlertObject.self, forPrimaryKey: primaryKey)
  }

  func deleteAll() {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.delete(self.alerts)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }
}
