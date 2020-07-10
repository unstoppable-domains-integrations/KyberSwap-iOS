// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNTrackerRateStorage {

  static var shared = KNTrackerRateStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var rates: [KNTrackerRate] {
    if self.realm == nil { return [] }
    if self.realm.objects(KNTrackerRate.self).isInvalidated { return [] }
    return self.realm.objects(KNTrackerRate.self)
      .filter { return !$0.tokenAddress.isEmpty }
  }

  func get(forPrimaryKey key: String) -> KNTrackerRate? {
    return self.realm.object(ofType: KNTrackerRate.self, forPrimaryKey: key)
  }

  func add(rates: [KNTrackerRate]) {
    if self.realm == nil { return }
    if self.realm.objects(KNTrackerRate.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.add(rates, update: .modified)
    try!self.realm.commitWrite()
  }

  func update(rates: [KNTrackerRate]) {
    if self.realm.objects(KNTrackerRate.self).isInvalidated { return }
    self.add(rates: rates)
  }

  func updateCachedRates(cachedRates: [KNRate]) {
    if self.realm == nil { return }
    if self.realm.objects(KNTrackerRate.self).isInvalidated { return }
    self.realm.beginWrite()
    // Note: Might need to improve this one
    self.rates.forEach({ trackerRate in
      if let rate = cachedRates.first(where: { trackerRate.tokenSymbol == $0.source }) {
        if rate.dest == "USD" {
          trackerRate.rateUSDNow = Double(rate.rate) / pow(10.0, 18.0)
        } else {
          trackerRate.rateETHNow = Double(rate.rate) / pow(10.0, 18.0)
        }
      }
    })
    try!self.realm.commitWrite()
  }

  func delete(rates: [KNTrackerRate]) {
    if self.realm == nil { return }
    if self.realm.objects(KNTrackerRate.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(rates)
    try! self.realm.commitWrite()
  }

  func deleteAll() {
    if self.realm == nil { return }
    if realm.objects(KNTrackerRate.self).isInvalidated { return }
    try! realm.write {
      realm.delete(realm.objects(KNTrackerRate.self))
    }
  }
}

extension KNTrackerRateStorage {
  func trackerRate(for token: TokenObject) -> KNTrackerRate? {
    return self.rates.first(where: { $0.isTrackerRate(for: token) })
  }
}
