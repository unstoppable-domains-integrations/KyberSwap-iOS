// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore

struct IEOGetContridbutorRemainingCapEncode: Web3Request {
  typealias Response = String
  //swiftlint:disable line_length
  static let abi = "{\"constant\": true, \"inputs\": [{\"name\": \"userId\", \"type\": \"uint256\"}], \"name\": \"getContributorRemainingCap\", \"outputs\": [[{ \"name\": \"capWei\", \"type\":\"uint256\" }]], \"payable\": false, \"stateMutability\": \"view\", \"type\": \"function\"}"

  let userID: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(IEOGetContridbutorRemainingCapEncode.abi), [\"\(userID.hexEncoded)\"])"
    return .script(command: run)
  }
}

struct IEOGetContridbutorRemainingCapDecode: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('uint', '\(data)')"
    return .script(command: run)
  }
}
