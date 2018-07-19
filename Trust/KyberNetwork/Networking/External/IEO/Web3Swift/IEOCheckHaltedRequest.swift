// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import TrustCore

struct IEOCheckHaltedEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\": true, \"inputs\": [], \"name\": \"haltedIEO\", \"outputs\": [{ \"name\": \"\", \"type\": \"bool\" }], \"payable\": false, \"stateMutability\": \"view\", \"type\": \"function\"}"

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(IEOCheckHaltedEncode.abi))"
    return .script(command: run)
  }
}

struct IEOCheckHaltedDecode: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('bool', '\(data)')"
    return .script(command: run)
  }
}
