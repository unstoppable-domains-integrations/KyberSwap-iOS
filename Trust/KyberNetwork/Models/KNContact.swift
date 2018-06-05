// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNContact: Object {

  @objc dynamic var address: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var lastUsed: Date = Date()

  convenience init(address: String, name: String) {
    self.init()
    self.name = name
    self.address = address
    self.lastUsed = Date()
  }

  override static func primaryKey() -> String {
    return "address"
  }
}
