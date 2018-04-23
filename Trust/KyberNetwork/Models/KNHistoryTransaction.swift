// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNHistoryTransaction: Object {

  @objc dynamic var id: String = ""
  @objc dynamic var blockNumber: Int = 0
  @objc dynamic var blockHash: String = ""
  @objc dynamic var blockTimestamp: Int64 = 0
  @objc dynamic var makerAddress: String = ""
  @objc dynamic var makerTokenAddress: String = ""
  @objc dynamic var makerTokenSymbol: String = ""
  @objc dynamic var makerTokenAmount: String = ""

  @objc dynamic var takerAddress: String = ""
  @objc dynamic var takerTokenAddress: String = ""
  @objc dynamic var takerTokenSymbol: String = ""
  @objc dynamic var takerTokenAmount: String = ""

  @objc dynamic var gasLimit: Int64 = 0
  @objc dynamic var gasPrice: Int64 = 0
  @objc dynamic var gasUsed: Int64 = 0
  @objc dynamic var collectedFees: String = ""

  // There are more information returned
  convenience init(dictionary: JSONDictionary) throws {
    self.init()
    self.id = try kn_cast(dictionary["tx"])
    self.blockNumber = try kn_cast(dictionary["blockNumber"])
    self.blockHash = try kn_cast(dictionary["blockHash"])
    self.blockTimestamp = try kn_cast(dictionary["blockTimestamp"])
    self.makerAddress = try kn_cast(dictionary["makerAddress"])
    self.makerTokenAddress = try kn_cast(dictionary["makerTokenAddress"])
    self.makerTokenSymbol = try kn_cast(dictionary["makerTokenSymbol"])
    self.makerTokenAmount = try kn_cast(dictionary["makerTokenAmount"])
    self.takerAddress = try kn_cast(dictionary["takerAddress"])
    self.takerTokenAddress = try kn_cast(dictionary["takerTokenAddress"])
    self.takerTokenSymbol = try kn_cast(dictionary["takerTokenSymbol"])
    self.takerTokenAmount = try kn_cast(dictionary["takerTokenAmount"])
    self.gasLimit = try kn_cast(dictionary["gasLimit"])
    self.gasPrice = try kn_cast(dictionary["gasPrice"])
    self.gasUsed = try kn_cast(dictionary["gasUsed"])
    self.collectedFees = try kn_cast(dictionary["collectedFees"])
  }

  override static func primaryKey() -> String? {
    return "id"
  }
}
