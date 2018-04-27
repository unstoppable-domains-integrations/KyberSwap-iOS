// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import TrustKeystore

// "ERC20 - Token Transfer Events" by Address
class KNTokenTransaction: Object {

  @objc dynamic var id: String = ""
  @objc dynamic var blockNumber: String = ""
  @objc dynamic var timeStamp: String = ""
  @objc dynamic var nonce: String = ""
  @objc dynamic var blockHash: String = ""
  @objc dynamic var from: String = ""
  @objc dynamic var contractAddress: String = ""
  @objc dynamic var to: String = ""
  @objc dynamic var value: String = ""
  @objc dynamic var tokenName: String = ""
  @objc dynamic var tokenSymbol: String = ""
  @objc dynamic var tokenDecimal: String = ""
  @objc dynamic var transactionIndex: String = ""
  @objc dynamic var gas: String = ""
  @objc dynamic var gasPrice: String = ""
  @objc dynamic var gasUsed: String = ""
  @objc dynamic var cumulativeGasUsed: String = ""
  @objc dynamic var input: String = ""
  @objc dynamic var confirmations: String = ""

  override static func primaryKey() -> String? {
    return "id"
  }

  override func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? KNTokenTransaction else { return false }
    return object.id == self.id
  }
}

extension KNTokenTransaction {
  func getToken() -> TokenObject? {
    guard let _ = Address(string: self.contractAddress) else { return nil }
    return TokenObject(
      contract: self.contractAddress,
      name: self.tokenName,
      symbol: self.tokenSymbol,
      decimals: Int(self.tokenDecimal) ?? 18,
      value: "0",
      isCustom: false,
      isDisabled: false
    )
  }
}
