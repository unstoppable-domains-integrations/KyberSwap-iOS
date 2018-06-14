// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore

struct IEODistributedTokensWeiEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\": true, \"inputs\": [], \"name\": \"distributedTokensTwei\", \"outputs\": [{ \"name\": \"\", \"type\": \"uint256\" }], \"payable\": false, \"stateMutability\": \"view\", \"type\": \"function\"}"

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(IEODistributedTokensWeiEncode.abi))"
    return .script(command: run)
  }
}

struct IEODistributedTokensWeiDecode: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('uint256', '\(data)')"
    return .script(command: run)
  }
}
