
// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNCoinTickerStorage {

  static let shared = KNCoinTickerStorage()
  private let realm: Realm

  init() {
    let config = RealmConfiguration.globalConfiguration(for: KNEnvironment.default.chainID)
    self.realm = try! Realm(configuration: config)
  }

  var coinTickers: [KNCoinTicker] {
    return self.realm.objects(KNCoinTicker.self)
      .sorted(byKeyPath: "rank", ascending: true)
      .filter { !$0.id.isEmpty }
  }

  func get(forPrimaryKey key: String) -> KNCoinTicker? {
    return self.realm.object(ofType: KNCoinTicker.self, forPrimaryKey: key)
  }

  func add(coinTickers: [KNCoinTicker]) {
    self.realm.beginWrite()
    self.realm.add(coinTickers, update: true)
    try!self.realm.commitWrite()
  }

  func update(coinTickers: [KNCoinTicker]) {
    self.add(coinTickers: coinTickers)
  }

  func delete(coinTickers: [KNCoinTicker]) {
    self.realm.beginWrite()
    self.realm.delete(coinTickers)
    try! self.realm.commitWrite()
  }

  func deleteAll() {
    try! realm.write {
      realm.delete(realm.objects(KNCoinTicker.self))
    }
  }
}
