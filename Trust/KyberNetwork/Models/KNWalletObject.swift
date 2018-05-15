// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNWalletObject: Object {

  @objc dynamic var address: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var icon: String = ""
  @objc dynamic var date: Date = Date()

  convenience init(address: String) {
    self.init()
    self.address = address
    // TODO: Implement it
    self.name = "Untitled"
    self.icon = "eth"
    self.date = Date()
  }

  override class func primaryKey() -> String? {
    return "address"
  }
}
