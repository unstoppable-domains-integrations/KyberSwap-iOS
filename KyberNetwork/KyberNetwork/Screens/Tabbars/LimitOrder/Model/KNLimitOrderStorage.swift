// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

class KNLimitOrderStorage {
  static let shared: KNLimitOrderStorage = KNLimitOrderStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var orders: [KNOrderObject] {
    if self.realm == nil { return [] }
    if self.realm.objects(KNOrderObject.self).isInvalidated { return [] }
    return self.realm.objects(KNOrderObject.self)
      .filter({ return $0.id != -1 })
  }

  func addNewOrder(_ order: KNOrderObject) {
    self.addNewOrders([order])
  }

  func addNewOrders(_ orders: [KNOrderObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.add(orders, update: false)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListOrdersNotificationKey)
  }

  func updateOrderState(_ orderID: Int, state: KNOrderState) {
    guard let order = self.getObject(primaryKey: orderID) else { return }
    let newOrder = order.clone()
    newOrder.stateValue = state.rawValue
    self.updateOrder(newOrder)
  }

  func updateOrder(_ order: KNOrderObject) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.add(orders, update: true)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListOrdersNotificationKey)
  }

  func updateOrdersFromServer(_ orders: [KNOrderObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    // filter removed alerts
    let orderIDs = orders.map({ return $0.id })
    let removedOrders = self.orders.filter({ return !orderIDs.contains($0.id) })
    self.realm.delete(removedOrders)
    self.realm.add(orders, update: true)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListOrdersNotificationKey)
  }

  func deleteOrder(_ order: KNOrderObject) {
    self.deleteOrders([order])
  }

  func deleteOrder(with ID: Int) {
    if self.realm == nil { return }
    guard let order = self.getObject(primaryKey: ID) else { return }
    self.deleteOrder(order)
  }

  func deleteOrders(_ orders: [KNOrderObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.delete(orders)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListOrdersNotificationKey)
  }

  func getObject(primaryKey: Int) -> KNOrderObject? {
    if self.realm == nil { return nil }
    return self.realm.object(ofType: KNOrderObject.self, forPrimaryKey: primaryKey)
  }

  func deleteAll() {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.delete(self.orders)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListOrdersNotificationKey)
  }
}
