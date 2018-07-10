// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import TrustCore

struct IEOGetRateEncode: Web3Request {
  typealias Response = String
  //swiftlint:disable line_length
  static let abi = "{\"constant\": true, \"inputs\": [], \"name\": \"getRate\", \"outputs\": [{ \"name\": \"rateNumerator\", \"type\": \"uint256\"}, {\"name\": \"rateDenominator\", \"type\": \"uint256\" }], \"payable\": false, \"stateMutability\": \"view\", \"type\": \"function\"}"

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(IEOGetRateEncode.abi))"
    return .script(command: run)
  }
}

struct IEOGetRateDecode: Web3Request {
  typealias Response = [String: String]

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameters([{ \"name\": \"rateNumerator\", \"type\": \"uint256\"}, {\"name\": \"rateDenominator\", \"type\": \"uint256\"}], '\(data)')"
    return .script(command: run)
  }
}
