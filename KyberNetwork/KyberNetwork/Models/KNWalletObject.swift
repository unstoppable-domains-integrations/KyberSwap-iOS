// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNWalletObject: Object {

  @objc dynamic var address: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var icon: String = ""
  @objc dynamic var isBackedUp: Bool = true
  @objc dynamic var date: Date = Date()

  convenience init(address: String, name: String = "Untitled", isBackedUp: Bool = true) {
    self.init()
    self.address = address
    self.name = name
    self.icon = "wallet_icon_\((KNWalletStorage.shared.wallets.count + 1) % 6)"
    self.date = Date()
    self.isBackedUp = isBackedUp
  }

  convenience init(address: String, name: String, icon: String, date: Date, isBackedUp: Bool = true) {
    self.init()
    self.address = address
    self.name = name
    self.icon = icon
    self.date = date
    self.isBackedUp = isBackedUp
  }

  func copy(withNewName newName: String) -> KNWalletObject {
    return KNWalletObject(
      address: self.address,
      name: newName,
      icon: self.icon,
      date: self.date,
      isBackedUp: self.isBackedUp
    )
  }

  override class func primaryKey() -> String? {
    return "address"
  }
}

class KNWalletPromoInfoStorage: NSObject {

  let userDefaults = UserDefaults.standard
  static let shared = KNWalletPromoInfoStorage()
  var kKeyPrefix: String {
    return "\(KNEnvironment.default.displayName)_\(KNEnvironment.default.chainID)_"
  }

  override init() {}

  func addWalletPromoInfo(address: String, destinationToken: String) {
    self.userDefaults.set(destinationToken, forKey: kKeyPrefix + address.lowercased())
    self.userDefaults.synchronize()
  }

  func removeWalletPromoInfo(address: String) {
    self.userDefaults.removeObject(forKey: kKeyPrefix + address.lowercased())
    self.userDefaults.synchronize()
  }

  func getDestinationToken(from address: String) -> String? {
    return self.userDefaults.object(forKey: kKeyPrefix + address.lowercased()) as? String
  }
}
