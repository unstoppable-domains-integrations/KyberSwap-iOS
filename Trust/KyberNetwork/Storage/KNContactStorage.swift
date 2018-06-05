// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNContactStorage {

  static let shared: KNContactStorage = KNContactStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var contacts: [KNContact] {
    return self.realm.objects(KNContact.self)
      .sorted(byKeyPath: "lastUsed", ascending: false)
      .filter { !$0.address.isEmpty }
  }

  func get(forPrimaryKey key: String) -> KNContact? {
    return self.realm.object(ofType: KNContact.self, forPrimaryKey: key)
  }

  fileprivate func add(contacts: [KNContact]) {
    self.realm.beginWrite()
    self.realm.add(contacts, update: true)
    try! self.realm.commitWrite()
  }

  func update(contacts: [KNContact]) {
    self.add(contacts: contacts)
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
  }

  func updateLastUsed(contact: KNContact) {
    try! self.realm.write {
      contact.lastUsed = Date()
    }
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
  }

  func delete(contacts: [KNContact]) {
    self.realm.beginWrite()
    self.realm.delete(contacts)
    try! self.realm.commitWrite()
  }

  func deleteAll() {
    try! realm.write {
      realm.delete(realm.objects(KNContact.self))
    }
  }
}
