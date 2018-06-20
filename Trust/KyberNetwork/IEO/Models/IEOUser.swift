// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class IEOUser: Object {

  @objc dynamic var userID: Int = -1
  @objc dynamic var name: String = ""
  @objc dynamic var contactType: String = ""
  @objc dynamic var contactID: String = ""
  @objc dynamic var kycStatus: String = ""
  @objc dynamic var tokenType: String = ""
  @objc dynamic var expireTime: Double = 0
  @objc dynamic var accessToken: String = ""
  @objc dynamic var refreshToken: String = ""
  var registeredAddress: List<String> = List<String>()

  convenience init(dict: JSONDictionary) {
    self.init()
    self.userID = dict["uid"] as? Int ?? -1
    self.name = dict["name"] as? String ?? ""
    self.contactType = dict["contact_type"] as? String ?? ""
    self.contactID = dict["contact_id"] as? String ?? ""
    self.kycStatus = dict["kyc_status"] as? String ?? ""
    self.registeredAddress = List<String>()
    if let arr = dict["active_wallets"] as? [String] {
      arr.forEach { self.registeredAddress.append($0) }
    }
  }

  func updateToken(dict: JSONDictionary) {
    self.tokenType = dict["token_type"] as? String ?? ""
    self.accessToken = dict["access_token"] as? String ?? ""
    self.expireTime = dict["expires_int"] as? Double ?? 0
    self.refreshToken = dict["refresh_token"] as? String ?? ""
  }

  override class func primaryKey() -> String? {
    return "userID"
  }
}
