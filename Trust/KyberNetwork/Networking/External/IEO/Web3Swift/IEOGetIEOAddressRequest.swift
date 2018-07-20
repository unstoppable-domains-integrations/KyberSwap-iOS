// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore

struct IEOGetIEOAddressEncode: Web3Request {
  typealias Response = String
  //swiftlint:disable line_length
  static let abi = "{\"constant\": true, \"inputs\": [{\"name\": \"\", \"type\": \"uint256\"}], \"name\": \"ieoAddress\", \"outputs\": [[{ \"name\": \"\", \"type\":\"address\" }]], \"payable\": false, \"stateMutability\": \"view\", \"type\": \"function\"}"

  let ieoID: Int

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(IEOGetIEOAddressEncode.abi), [\"\(BigInt(ieoID).description)\"])"
    return .script(command: run)
  }
}

struct IEOGetIEOAddressDecode: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('address', '\(data)')"
    return .script(command: run)
  }
}
