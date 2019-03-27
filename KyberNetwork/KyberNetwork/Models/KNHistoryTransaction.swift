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

  @objc dynamic var compoundKey: String = ""

  // There are more information returned
  convenience init(dictionary: JSONDictionary) {
    self.init()
    self.id = dictionary["tx"] as? String ?? ""
    self.blockNumber = dictionary["blockNumber"] as? Int ?? 0
    self.blockHash = dictionary["blockHash"] as? String ?? ""
    self.blockTimestamp = dictionary["blockTimestamp"] as? Int64 ?? 0
    self.makerAddress = dictionary["makerAddress"] as? String ?? ""
    self.makerTokenAddress = dictionary["makerTokenAddress"] as? String ?? ""
    self.makerTokenSymbol = dictionary["makerTokenSymbol"] as? String ?? ""
    self.makerTokenAmount = dictionary["makerTokenAmount"] as? String ?? ""
    self.takerAddress = dictionary["takerAddress"] as? String ?? ""
    self.takerTokenAddress = dictionary["takerTokenAddress"] as? String ?? ""
    self.takerTokenSymbol = dictionary["takerTokenSymbol"] as? String ?? ""
    self.takerTokenAmount = dictionary["takerTokenAmount"] as? String ?? ""
    self.gasLimit = dictionary["gasLimit"] as? Int64 ?? 0
    self.gasPrice = dictionary["gasPrice"] as? Int64 ?? 0
    self.gasUsed = dictionary["gasUsed"] as? Int64 ?? 0
    self.collectedFees = dictionary["collectedFees"] as? String ?? ""
    self.compoundKey = "\(id)\(makerAddress)\(takerAddress)"
  }

  override static func primaryKey() -> String? {
    return "compoundKey"
  }
}
