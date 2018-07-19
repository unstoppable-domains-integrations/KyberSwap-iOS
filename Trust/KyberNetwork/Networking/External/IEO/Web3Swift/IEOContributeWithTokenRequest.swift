// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import BigInt
import TrustCore

//swiftlint:disable line_length
struct IEOContributeWithTokenEncode: Web3Request {
  typealias Response = String
  static let abi = "{\"constant\":false,\"inputs\":[{\"name\":\"userId\",\"type\":\"uint256\"}, {\"name\":\"token\",\"type\":\"address\"}, {\"name\":\"amountTwei\",\"type\":\"uint256\"}, {\"name\":\"minConversionRate\",\"type\":\"uint256\"}, {\"name\":\"maxDestAmountWei\",\"type\":\"uint256\"}, {\"name\":\"network\",\"type\":\"address\"}, {\"name\":\"kyberIEO\",\"type\":\"address\"}, {\"name\":\"v\",\"type\":\"uint8\"}, {\"name\":\"r\",\"type\":\"bytes32\"},{\"name\":\"s\",\"type\":\"bytes32\"}],\"name\":\"contributeWithToken\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"}"

  let transaction: IEODraftTransaction

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(IEOContributeWithTokenEncode.abi), [\"\(transaction.userID.description)\", \"\(transaction.token.address.description)\", \"\(transaction.amount.description)\", \"\(transaction.minRate?.description ?? "")\", \"\(transaction.maxDestAmount?.description ?? "0x")\", \"\(KNEnvironment.default.knCustomRPC?.networkAddress ?? "0x")\", \"\(transaction.ieo.contract)\", \"\(transaction.v)\", \"\(transaction.r)\", \"\(transaction.s)\"])"
    return .script(command: run)
  }
}
