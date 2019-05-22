// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

enum KNOrderState: Int {
  case open
  case filled
  case cancelled
  case unknown
}

class KNOrderObject: Object {

  @objc dynamic var id: Int = -1
  @objc dynamic var sourceToken: String = ""
  @objc dynamic var destToken: String = ""
  @objc dynamic var targetPrice: Double = 0.0
  @objc dynamic var sourceAmount: Double = 0.0
  @objc dynamic var fee: Double = 0.0
  @objc dynamic var sender: String = ""
  @objc dynamic var createdDate: TimeInterval = 0.0
  @objc dynamic var updatedDate: TimeInterval = 0.0
  @objc dynamic var filledDate: TimeInterval = 0.0
  @objc dynamic var stateValue: Int = KNOrderState.open.rawValue

  convenience init(
    id: Int = -1,
    from: String,
    to: String,
    amount: Double,
    price: Double,
    fee: Double,
    sender: String,
    createdDate: TimeInterval = Date().timeIntervalSince1970,
    updatedDate: TimeInterval = Date().timeIntervalSince1970,
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
    self.updatedDate = updatedDate
    self.filledDate = filledDate
    self.stateValue = stateValue
  }

  var state: KNOrderState { return KNOrderState(rawValue: self.stateValue) ?? .open }

  var dateToDisplay: Date {
    if self.filledDate != 0.0 { return Date(timeIntervalSince1970: self.filledDate) }
    return Date(timeIntervalSince1970: self.createdDate)
  }

  override class func primaryKey() -> String? {
    return "id"
  }

  static func getOrderObject(from order: KNLimitOrder) -> KNOrderObject {
    let isFilled = arc4random() % 2 == 1
    let object = KNOrderObject(
      id: Int(arc4random()),
      from: order.from.symbol,
      to: order.to.symbol,
      amount: Double(order.srcAmount) / pow(10.0, Double(order.from.decimals)),
      price: Double(order.targetRate) / pow(10.0, Double(order.to.decimals)),
      fee: Double(order.fee) / pow(10.0, Double(order.from.decimals)),
      sender: order.account.address.description,
      createdDate: Date().timeIntervalSince1970 - Double(arc4random() % 100) * 24.0 * 60.0 * 60.0,
      updatedDate: Date().timeIntervalSince1970,
      filledDate: isFilled ? Date().timeIntervalSince1970 : 0.0,
      stateValue: isFilled ? KNOrderState.filled.rawValue : KNOrderState.open.rawValue
    )
    return object
  }
}
