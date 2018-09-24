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
    return self.objects.first(where: { $0.isSignedIn })
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
  func updateToken(object: IEOUser, type: String, accessToken: String, refreshToken: String, expireTime: Double) -> IEOUser {
    try! self.realm.write {
      object.updateToken(
        type: type,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expireTime: expireTime
      )
    }
    return object
  }

  func getObject(primaryKey: Int) -> IEOUser? {
    return self.realm.object(ofType: IEOUser.self, forPrimaryKey: primaryKey)
  }

  func delete(objects: [IEOUser]) {
    if self.realm == nil { return }
    objects.forEach { $0.removeKYCStep() }
    try! self.realm.write {
      self.realm.delete(objects)
    }
  }

  func signedOut() {
    if self.realm == nil { return }
//    guard let user = self.user else { return }
//    for env in KNEnvironment.allEnvironments() {
//      let config = RealmConfiguration.kyberGOConfiguration(for: user.userID, chainID: env.chainID)
//      let realm = try! Realm(configuration: config)
//      realm.beginWrite()
//      realm.deleteAll()
//      try! realm.commitWrite()
//    }

    self.delete(objects: self.objects)
  }

  func signedIn() {
    if self.realm == nil { return }
    guard let user = self.objects.first else { return }
    self.realm.beginWrite()
    user.isSignedIn = true
    self.realm.add(user, update: true)
    try! self.realm.commitWrite()
    // Remove all other users
    let removedUsers = self.objects.filter({ return !$0.isSignedIn })
    self.delete(objects: removedUsers)
  }
}
