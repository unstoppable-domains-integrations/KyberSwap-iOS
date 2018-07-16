// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class IEOTransactionStorage {

  static let shared = IEOTransactionStorage()
  private(set) var realm: Realm!

  init() { self.loggedIn() }

  func loggedOut() {
    self.deleteAll()
    self.realm = nil
  }

  func loggedIn() {
    guard let user = IEOUserStorage.shared.user else { return }
    let config = RealmConfiguration.kyberGOConfiguration(for: user.userID)
    self.realm = try! Realm(configuration: config)
  }

  var objects: [IEOTransaction] {
    return self.realm.objects(IEOTransaction.self)
      .sorted(byKeyPath: "createdDate", ascending: true)
      .filter { !($0.id != -1) }
  }

  func add(objects: [IEOTransaction]) {
    self.realm.beginWrite()
    self.realm.add(objects, update: true)
    try! self.realm.commitWrite()
  }

  func update(objects: [IEOTransaction]) {
    self.add(objects: objects)
  }

  func getObject(primaryKey: Int) -> IEOTransaction? {
    return self.realm.object(ofType: IEOTransaction.self, forPrimaryKey: primaryKey)
  }

  func deleteAll() {
    try! realm.write {
      realm.delete(realm.objects(IEOTransaction.self))
    }
  }
}
