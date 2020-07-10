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
    if self.realm == nil { return [] }
    if self.realm.objects(KNContact.self).isInvalidated { return [] }
    return self.realm.objects(KNContact.self)
      .sorted(byKeyPath: "lastUsed", ascending: false)
      .filter { return !$0.address.isEmpty }
  }

  func get(forPrimaryKey key: String) -> KNContact? {
    if self.realm == nil { return nil }
    if realm.objects(KNContact.self).isInvalidated { return nil }
    return self.realm.object(ofType: KNContact.self, forPrimaryKey: key)
  }

  fileprivate func add(contacts: [KNContact]) {
    if self.realm == nil { return }
    if realm.objects(KNContact.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.add(contacts, update: .modified)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
  }

  func update(contacts: [KNContact]) {
    self.add(contacts: contacts)
  }

  func updateLastUsed(contact: KNContact) {
    if self.realm == nil { return }
    if realm.objects(KNContact.self).isInvalidated { return }
    self.realm.beginWrite()
    contact.lastUsed = Date()
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
  }

  func delete(contacts: [KNContact]) {
    if self.realm == nil { return }
    if realm.objects(KNContact.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(contacts)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
  }

  func deleteAll() {
    if self.realm == nil { return }
    if realm.objects(KNContact.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(realm.objects(KNContact.self))
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
  }
}
