// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import TrustCore

struct IEOCheckWhiteListedAddressEncode: Web3Request {
  typealias Response = String
  //swiftlint:disable line_length
  static let abi = "{\"constant\": true, \"inputs\": [{\"name\": \"\", \"type\": \"address\"}], \"name\": \"whiteListedAddresses\", \"outputs\": [[{ \"name\": \"\", \"type\":\"bool\" }]], \"payable\": false, \"stateMutability\": \"view\", \"type\": \"function\"}"

  let address: Address

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(IEOCheckWhiteListedAddressEncode.abi), [\"\(address)\"])"
    return .script(command: run)
  }
}
