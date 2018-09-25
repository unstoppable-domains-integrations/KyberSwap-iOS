// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

enum IEOKYCStep: Int {
  case personalInfo = 1
  case identity = 2
  case submit = 3
}

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
  @objc dynamic var isSignedIn: Bool = true
  @objc dynamic var avatarURL: String = ""
  var registeredAddress: List<String> = List<String>()

  convenience init(dict: JSONDictionary) {
    self.init()
    self.userID = dict["uid"] as? Int ?? -1
    self.name = dict["name"] as? String ?? ""
    self.contactType = dict["contact_type"] as? String ?? ""
    self.contactID = dict["contact_id"] as? String ?? ""
    self.kycStatus = dict["kyc_status"] as? String ?? ""
    self.registeredAddress = List<String>()
    self.avatarURL = dict["avatar_url"] as? String ?? ""
    if let arr = dict["active_wallets"] as? [String] {
      arr.forEach { self.registeredAddress.append($0.lowercased()) }
    }
    let step = dict["kyc_step"] as? Int ?? 1
    self.updateKYCStep(step)

    if let kycInfoDict = dict["kyc_info"] as? JSONDictionary {
      let kycObject = IEOUserKYCDetails(userID: self.userID, dict: kycInfoDict)
      IEOUserStorage.shared.updateKYCDetails(object: kycObject)
    } else {
      IEOUserStorage.shared.deleteKYCDetails(for: self.userID)
    }
  }

  func updateToken(type: String, accessToken: String, refreshToken: String, expireTime: Double) {
    self.tokenType = type
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.expireTime = expireTime
  }

  fileprivate func updateKYCStep(_ step: Int) {
    let userDefaults = UserDefaults.standard
    userDefaults.set(step, forKey: "kUserKYCStepKey_\(self.userID)")
    userDefaults.synchronize()
  }

  func removeKYCStep() {
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "kUserKYCStepKey_\(self.userID)")
    userDefaults.synchronize()
  }

  var kycStep: Int {
    return UserDefaults.standard.object(forKey: "kUserKYCStepKey_\(self.userID)") as? Int ?? 1
  }

  var kycDetails: IEOUserKYCDetails? {
    return IEOUserStorage.shared.getKYCDetails(for: self.userID)
  }

  override class func primaryKey() -> String? {
    return "userID"
  }
}

class IEOUserKYCDetails: Object {
  @objc dynamic var userID: Int = -1
  @objc dynamic var firstName: String = ""
  @objc dynamic var lastName: String = ""
  @objc dynamic var nationality: String = ""
  @objc dynamic var country: String = ""
  @objc dynamic var gender: Bool = true
  @objc dynamic var dob: String = ""
  @objc dynamic var documentType: String = ""
  @objc dynamic var documentNumber: String = ""
  @objc dynamic var documentPhoto: String = ""
  @objc dynamic var documentSelfiePhoto: String = ""

  convenience init(userID: Int, dict: JSONDictionary) {
    self.init()
    self.userID = userID
    self.firstName = dict["first_name"] as? String ?? ""
    self.lastName = dict["last_name"] as? String ?? ""
    self.nationality = dict["nationality"] as? String ?? ""
    self.country = dict["country"] as? String ?? ""
    self.gender = dict["gender"] as? Bool ?? true
    self.dob = dict["dob"] as? String ?? ""
    self.documentType = dict["document_type"] as? String ?? ""
    self.documentNumber = dict["document_id"] as? String ?? ""
    self.documentPhoto = dict["photo_identity_doc"] as? String ?? ""
    self.documentSelfiePhoto = dict["photo_selfie"] as? String ?? ""
  }

  override class func primaryKey() -> String? {
    return "userID"
  }
}
