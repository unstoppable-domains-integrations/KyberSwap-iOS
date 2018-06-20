// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import BigInt

//swiftlint:disable line_length
struct IEOContributeEncode: Web3Request {
  typealias Response = String
  static let abi = "{\"constant\":false,\"inputs\":[{\"name\":\"contributor\",\"type\":\"address\"}, {\"name\":\"userId\",\"type\":\"uint256\"},{\"name\":\"v\",\"type\":\"uint8\"}, {\"name\":\"r\",\"type\":\"bytes32\"},{\"name\":\"s\",\"type\":\"bytes32\"}],\"name\":\"contribute\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"}"

  let transaction: IEODraftTransaction

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(IEOContributeEncode.abi), [\"\(transaction.wallet.address)\", \"\(transaction.userID.description)\", \"\(transaction.v)\", \"\(transaction.r)\", \"\(transaction.s)\"])"
    return .script(command: run)
  }
}
