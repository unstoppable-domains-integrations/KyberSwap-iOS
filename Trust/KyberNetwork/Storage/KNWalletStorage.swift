// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNWalletStorage {

  static var shared = KNWalletStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var wallets: [KNWalletObject] {
    return self.realm.objects(KNWalletObject.self)
      .sorted(byKeyPath: "date", ascending: true)
      .filter { !$0.address.isEmpty }
  }

  func get(forPrimaryKey key: String) -> KNWalletObject? {
    return self.realm.object(ofType: KNWalletObject.self, forPrimaryKey: key)
  }

  func add(wallets: [KNWalletObject]) {
    self.realm.beginWrite()
    self.realm.add(wallets, update: true)
    try!self.realm.commitWrite()
  }

  func update(wallets: [KNWalletObject]) {
    self.add(wallets: wallets)
  }

  func delete(wallets: [KNWalletObject]) {
    self.realm.beginWrite()
    self.realm.delete(wallets)
    try! self.realm.commitWrite()
  }

  func deleteAll() {
    try! realm.write {
      realm.delete(realm.objects(KNWalletObject.self))
    }
  }
}
