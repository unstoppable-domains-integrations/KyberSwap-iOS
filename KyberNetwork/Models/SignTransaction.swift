// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt
import TrustCore
import TrustKeystore

public struct SignTransaction {
    let value: BigInt
    let account: Account
    let to: Address?
    let nonce: Int
    let data: Data
    let gasPrice: BigInt
    let gasLimit: BigInt
    let chainID: Int
}

extension SignTransaction {
  func toTransaction(hash: String, fromAddr: String, type: TransactionType = .earn) -> Transaction {
    return Transaction(
      id: hash,
      blockNumber: 0,
      from: fromAddr,
      to: self.to?.description ?? "",
      value: self.value.description,
      gas: self.gasLimit.description,
      gasPrice: self.gasPrice.description,
      gasUsed: self.gasLimit.description,
      nonce: "\(self.nonce)",
      date: Date(),
      localizedOperations: [],
      state: .pending,
      type: type
    )
  }
}
