// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNTransaction: NSObject {

  let txHash: String
  let actualDestAmount: BigInt
  let actualSrcAmount: BigInt
  let dest: String
  let source: String
  let blockNumber: Int
  let timeStamp: TimeInterval

  init(dictionary: JSONDictionary) throws {
    txHash = try kn_cast(dictionary["txHash"])
    timeStamp = try kn_cast(dictionary["timestamp"] as? String ?? "0.0")
    blockNumber = try kn_cast(dictionary["blockNumber"] as? String ?? "0")
    source = try kn_cast(dictionary["source"])
    dest = try kn_cast(dictionary["dest"])
    let destAmountString: String = try kn_cast(dictionary["actualDestAmount"])
    actualDestAmount = BigInt(Double(destAmountString) ?? 0.0)
    let srcAmountString: String = try kn_cast(dictionary["actualSrcAmount"])
    actualSrcAmount = BigInt(Double(srcAmountString) ?? 0.0)
  }
}
