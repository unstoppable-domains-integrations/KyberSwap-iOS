// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

enum KNOrderState: Int {
  case open
  case inProgress
  case filled
  case cancelled
  case invalidated
  case unknown
}

class KNOrderObject: NSObject {

  @objc dynamic var id: Int = -1
  @objc dynamic var sourceToken: String = ""
  @objc dynamic var destToken: String = ""
  @objc dynamic var targetPrice: Double = 0.0
  @objc dynamic var sourceAmount: Double = 0.0
  @objc dynamic var fee: Int = 10
  @objc dynamic var nonce: Int = 0
  @objc dynamic var sender: String = ""
  @objc dynamic var createdDate: TimeInterval = 0.0
  @objc dynamic var filledDate: TimeInterval = 0.0
  @objc dynamic var messages: String = ""
  @objc dynamic var txHash: String?
  @objc dynamic var stateValue: Int = KNOrderState.open.rawValue

  convenience init(
    id: Int = -1,
    from: String,
    to: String,
    amount: Double,
    price: Double,
    fee: Int,
    sender: String,
    createdDate: TimeInterval = Date().timeIntervalSince1970,
    filledDate: TimeInterval = 0.0,
    stateValue: Int = KNOrderState.open.rawValue
    ) {
    self.init()
    self.id = id
    self.sourceToken = from
    self.destToken = to
    self.sourceAmount = amount
    self.targetPrice = price
    self.fee = fee
    self.sender = sender
    self.createdDate = createdDate
    self.filledDate = filledDate
    self.stateValue = stateValue
  }

  convenience init(json: JSONDictionary) {
    self.init()
    self.id = json["id"] as? Int ?? -1
    self.sourceToken = json["src"] as? String ?? ""
    self.destToken = json["dst"] as? String ?? ""
    self.sourceAmount = json["src_amount"] as? Double ?? 0.0
    self.targetPrice = json["min_rate"] as? Double ?? 0.0
    self.fee = json["fee"] as? Int ?? 0
    self.sender = json["addr"] as? String ?? ""
    self.nonce = json["nonce"] as? Int ?? 0
    self.stateValue = {
      let status = json["status"] as? String ?? ""
      if status == "active" { return 0 }
      if status == "pending" { return 1 }
      if status == "filled" { return 2 }
      if status == "cancelled" { return 3 }
      if status == "invalid" { return 4 }
      return 5
    }()
    self.createdDate = json["created_at"] as? Double ?? 0.0
    self.filledDate = json["updated_at"] as? Double ?? 0.0
    self.txHash = json["tx_hash"] as? String
    self.messages = json["messages"] as? String ?? ""
  }

  var state: KNOrderState { return KNOrderState(rawValue: self.stateValue) ?? .open }

  var dateToDisplay: Date {
    if self.filledDate != 0.0 { return Date(timeIntervalSince1970: self.filledDate) }
    return Date(timeIntervalSince1970: self.createdDate)
  }

  var srcTokenSymbol: String {
    return self.sourceToken
  }

  var destTokenSymbol: String {
    return self.destToken
  }

//  override class func primaryKey() -> String? {
//    return "id"
//  }

  static func getOrderObject(from order: KNLimitOrder) -> KNOrderObject {
    let state = Int(arc4random() % 5)
    let isFilled = arc4random() % 2 == 1
    let object = KNOrderObject(
      id: Int(arc4random()),
      from: order.from.symbol,
      to: order.to.symbol,
      amount: Double(order.srcAmount) / pow(10.0, Double(order.from.decimals)),
      price: Double(order.targetRate) / pow(10.0, Double(order.to.decimals)),
      fee: 10,
      sender: order.account.address.description,
      createdDate: Date().timeIntervalSince1970 - Double(arc4random() % 100) * 24.0 * 60.0 * 60.0,
      filledDate: isFilled ? Date().timeIntervalSince1970 : 0.0,
      stateValue: state
    )
    return object
  }
}
