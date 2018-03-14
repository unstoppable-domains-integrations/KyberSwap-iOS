// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt

struct KNGetExpectedRateEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"}, {\"name\":\"dest\",\"type\":\"address\"},{\"name\":\"srcQty\",\"type\":\"uint256\"}],\"name\":\"getExpectedRate\",\"outputs\":[{\"name\":\"expectedRate\",\"type\":\"uint256\"}, {\"name\":\"slippageRate\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

  let source: Address
  let dest: Address
  let amount: BigInt

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(KNGetExpectedRateEncode.abi), [\"\(source.description)\", \"\(dest.description)\", \"\(amount.description)\"])"
    return .script(command: run)
  }
}

struct KNGetExpectedRateDecode: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter(\"uint\", '\(data)')"
    return .script(command: run)
  }
}
