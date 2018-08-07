// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import RealmSwift

enum KNTransactionType {
  case transfer(UnconfirmedTransaction)
  case exchange(KNDraftExchangeTransaction)
  case buyTokenSale(IEODraftTransaction)

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
}
