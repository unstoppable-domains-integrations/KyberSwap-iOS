// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNAlertStorage: NSObject {
  static let shared: KNAlertStorage = KNAlertStorage()

  let kListAlertsKey: String = "kListAlertsKey"
  let userDefaults = UserDefaults.standard

  var alerts: [KNAlertObject] {
    let jsonArr = self.userDefaults.object(forKey: kListAlertsKey) as? [JSONDictionary] ?? []
    return jsonArr.map({ return KNAlertObject(json: $0) })
  }

  var isMaximumAlertsReached: Bool { return self.alerts.count >= 10 }

  func addNewAlert(_ alert: KNAlertObject) {
    var allAlerts = self.alerts
    allAlerts.append(alert)
    self.saveAlerts(allAlerts)
  }

  func updateAlert(_ alert: KNAlertObject) {
    let alerts = self.alerts
    guard alerts.first(where: { return $0.id == alert.id }) != nil else { return }
    var newAlerts = alerts.filter({ return $0.id != alert.id })
    newAlerts.append(alert)
    self.saveAlerts(newAlerts)
  }

  func deleteAlert(_ alert: KNAlertObject) {
    let alerts = self.alerts
    guard alerts.first(where: { return $0.id == alert.id }) != nil else { return }
    let newAlerts = alerts.filter({ return $0.id != alert.id })
    self.saveAlerts(newAlerts)
  }

  func triggeredAnAlert(_ alert: KNAlertObject) {
    let newAlert = alert.triggered()
    self.updateAlert(newAlert)
  }

  func saveAlerts(_ alerts: [KNAlertObject]) {
    let jsonArr = alerts.map({ return $0.json })
    self.userDefaults.set(jsonArr, forKey: kListAlertsKey)
    self.userDefaults.synchronize()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }
}
