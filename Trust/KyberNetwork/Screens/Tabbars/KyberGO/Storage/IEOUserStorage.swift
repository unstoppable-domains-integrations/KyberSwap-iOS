// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

class IEOUserStorage {
  static let shared = IEOUserStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var user: IEOUser? {
    return self.objects.first
  }

  var objects: [IEOUser] {
    return self.realm.objects(IEOUser.self)
      .sorted(byKeyPath: "userID", ascending: true)
      .filter { $0.userID != -1 }
  }

  func add(objects: [IEOUser]) {
    self.realm.beginWrite()
    self.realm.add(objects, update: true)
    try! self.realm.commitWrite()
  }

  func update(objects: [IEOUser]) {
    self.add(objects: objects)
  }

  @discardableResult
  func updateToken(object: IEOUser, dict: JSONDictionary) -> IEOUser {
    try! self.realm.write {
      object.updateToken(dict: dict)
    }
    return object
  }

  func getObject(primaryKey: Int) -> IEOUser? {
    return self.realm.object(ofType: IEOUser.self, forPrimaryKey: primaryKey)
  }

  func deleteAll() {
    IEOTransactionStorage.shared.deleteAll()
    try! realm.write {
      realm.delete(realm.objects(IEOUser.self))
    }
  }}
