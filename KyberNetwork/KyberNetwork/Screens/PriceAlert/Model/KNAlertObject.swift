// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNAlertState: Int {
  case active
  case cancelled
  case triggered
  case deleted
}

class KNAlertObject {

  let id: String
  let token: String
  let currency: String
  let price: Double
  let isAbove: Bool
  let createdDate: TimeInterval
  let updatedDate: TimeInterval
  let triggeredDate: TimeInterval?
  let state: KNAlertState

  init(token: String, currency: String, price: Double, isAbove: Bool) {
    self.id = UUID().uuidString
    self.token = token
    self.currency = currency
    self.price = price
    self.isAbove = isAbove
    self.createdDate = Date().timeIntervalSince1970
    self.updatedDate = Date().timeIntervalSince1970
    self.triggeredDate = nil
    self.state = .active
  }

  init(json: JSONDictionary) {
    self.id = json["id"] as? String ?? ""
    self.token = json["token"] as? String ?? ""
    self.currency = json["currency"] as? String ?? ""
    self.price = json["price"] as? Double ?? 0.0
    self.isAbove = json["isAbove"] as? Bool ?? false
    self.createdDate = json["createdDate"] as? TimeInterval ?? 0.0
    self.updatedDate = json["updatedDate"] as? TimeInterval ?? 0.0
    self.triggeredDate = json["triggeredDate"] as? TimeInterval
    self.state = KNAlertState(rawValue: json["state"] as? Int ?? 0) ?? .active
  }

  var json: JSONDictionary {
    var data: JSONDictionary = [
      "id": self.id,
      "token": self.token,
      "currency": self.currency,
      "price": self.price,
      "isAbove": self.isAbove,
      "createdDate": self.createdDate,
      "updatedDate": self.updatedDate,
      "state": self.state.rawValue,
    ]
    if let triggeredDate = self.triggeredDate {
      data["triggeredDate"] = triggeredDate
    }
    return data
  }

  func triggered() -> KNAlertObject {
    var json = self.json
    json["triggeredDate"] = Date().timeIntervalSince1970
    json["updatedDate"] = Date().timeIntervalSince1970
    json["state"] = KNAlertState.triggered.rawValue
    return KNAlertObject(json: json)
  }
}
