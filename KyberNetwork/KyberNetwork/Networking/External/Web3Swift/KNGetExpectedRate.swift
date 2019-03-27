// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt
import TrustCore

struct KNGetExpectedRateEncode: Web3Request {
  typealias Response = String

  //swiftlint:disable line_length
  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"}, {\"name\":\"dest\",\"type\":\"address\"},{\"name\":\"srcQty\",\"type\":\"uint256\"}],\"name\":\"getExpectedRate\",\"outputs\":[{\"name\":\"expectedRate\",\"type\":\"uint256\"}, {\"name\":\"slippageRate\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

  let source: Address
  let dest: Address
  let amount: BigInt

  var type: Web3RequestType {
    let official = amount | BigInt(2).power(255) // using official Kyber's reserve
    let run = "web3.eth.abi.encodeFunctionCall(\(KNGetExpectedRateEncode.abi), [\"\(source.description)\", \"\(dest.description)\", \"\(official.hexEncoded)\"])"
    return .script(command: run)
  }
}

struct KNGetExpectedRateDecode: Web3Request {
  typealias Response = [String: String]

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameters([{\"name\":\"expectedRate\",\"type\":\"uint256\"}, {\"name\":\"slippageRate\",\"type\":\"uint256\"}], '\(data)')"
    return .script(command: run)
  }
}
