// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class IEOObjectStorage {

  static let shared = IEOObjectStorage()

  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var objects: [IEOObject] {
    return self.realm.objects(IEOObject.self)
      .sorted(byKeyPath: "startDate", ascending: true)
      .filter { !($0.id == -1) }
  }

  func add(objects: [IEOObject]) {
    self.realm.beginWrite()
    self.realm.add(objects, update: true)
    try! self.realm.commitWrite()
  }

  func update(objects: [IEOObject]) {
    self.add(objects: objects)
  }

  @discardableResult
  func update(raised: Double, object: IEOObject) -> IEOObject {
    try! self.realm.write {
      object.raised = raised
      if object.endDate.timeIntervalSince(Date()) <= 0.0 || object.soldOut {
        object.needsUpdateRaised = false
      }
    }
    self.update(objects: [object])
    return object
  }

  @discardableResult
  func update(isHalted: Bool, object: IEOObject) -> IEOObject {
    try! self.realm.write {
      object.halted = isHalted
    }
    self.update(objects: [object])
    return object
  }

  @discardableResult
  func update(rate: String, object: IEOObject) -> IEOObject {
    try! self.realm.write {
      object.rate = rate
      if object.endDate.timeIntervalSince(Date()) <= 60.0 || object.soldOut {
        object.needsUpdateRate = false
      }
    }
    self.update(objects: [object])
    return object
  }

  func update(object: IEOObject, from objc: IEOObject) -> IEOObject {
    try! self.realm.write {
      object.rate = objc.rate
      object.raised = objc.raised
      object.needsUpdateRaised = objc.needsUpdateRaised
      object.needsUpdateRate = objc.needsUpdateRate
    }
    return object
  }

  func getObject(primaryKey: Int) -> IEOObject? {
    return self.realm.object(ofType: IEOObject.self, forPrimaryKey: primaryKey)
  }

  func deleteAll() {
    try! realm.write {
      realm.delete(realm.objects(IEOObject.self))
    }
  }
}
