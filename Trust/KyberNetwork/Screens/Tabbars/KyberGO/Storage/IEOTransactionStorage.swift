// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class IEOTransactionStorage {

  static let shared = IEOTransactionStorage()
  private(set) var realm: Realm!

  init() {
    guard let user = IEOUserStorage.shared.user else { return }
    let config = RealmConfiguration.kyberGOConfiguration(for: user.userID)
    self.realm = try! Realm(configuration: config)
  }

  func userLoggedIn() {
    guard let user = IEOUserStorage.shared.user else { return }
    let config = RealmConfiguration.kyberGOConfiguration(for: user.userID)
    self.realm = try! Realm(configuration: config)
  }

  var objects: [IEOTransaction] {
    if self.realm == nil { return [] }
    return self.realm.objects(IEOTransaction.self)
      .sorted(byKeyPath: "createdDate", ascending: false)
      .filter { $0.id != -1 }
  }

  func add(objects: [IEOTransaction]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.add(objects, update: true)
    try! self.realm.commitWrite()
  }

  func update(objects: [IEOTransaction]) {
    self.add(objects: objects)
  }

  func getObject(primaryKey: Int) -> IEOTransaction? {
    if self.realm == nil { return nil }
    return self.realm.object(ofType: IEOTransaction.self, forPrimaryKey: primaryKey)
  }

  func markAllViewed() {
    if self.realm == nil { return }
    self.realm.beginWrite()
    let objects = self.objects
    objects.forEach({ $0.viewed = true })
    try! self.realm.commitWrite()
  }

  func deleteAll() {
    if self.realm == nil { return }
    try! realm.write {
      realm.delete(realm.objects(IEOTransaction.self))
    }
  }
}
