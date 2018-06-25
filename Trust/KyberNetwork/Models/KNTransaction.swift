// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import RealmSwift

enum KNTransactionType {
  case transfer(UnconfirmedTransaction)
  case exchange(KNDraftExchangeTransaction)

  var isTransfer: Bool {
    if case .transfer = self { return true }
    return false
  }
}

class KNTransaction: Object {

  @objc dynamic var id: String = ""
  @objc dynamic var timeStamp: String = ""
  @objc dynamic var nonce: String = ""
  @objc dynamic var blockHash: String = ""
  @objc dynamic var transactionIndex: String = ""
  @objc dynamic var from: String = ""
  @objc dynamic var to: String = ""
  @objc dynamic var value: String = ""
  @objc dynamic var gas: String = ""
  @objc dynamic var gasPrice: String = ""
  @objc dynamic var isError: String = ""
  @objc dynamic var txreceipt_status: String = ""
  @objc dynamic var input: String = ""
  @objc dynamic var contractAddress: String = ""
  @objc dynamic var cumulativeGasUsed: String = ""
  @objc dynamic var gasUsed: String = ""
  @objc dynamic var confirmations: String = ""

//  let txHash: String
//  let actualDestAmount: BigInt
//  let actualSrcAmount: BigInt
//  let dest: String
//  let source: String
//  let blockNumber: Int
//  let timeStamp: TimeInterval
//
//  init(dictionary: JSONDictionary) throws {
//    txHash = try kn_cast(dictionary["txHash"])
//    timeStamp = try kn_cast(dictionary["timestamp"] as? String ?? "0.0")
//    blockNumber = try kn_cast(dictionary["blockNumber"] as? String ?? "0")
//    source = try kn_cast(dictionary["source"])
//    dest = try kn_cast(dictionary["dest"])
//    let destAmountString: String = try kn_cast(dictionary["actualDestAmount"])
//    actualDestAmount = BigInt(Double(destAmountString) ?? 0.0)
//    let srcAmountString: String = try kn_cast(dictionary["actualSrcAmount"])
//    actualSrcAmount = BigInt(Double(srcAmountString) ?? 0.0)
//  }
}
