// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore

//swiftlint:disable line_length
struct KNExchangeRequestEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\":false,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"}, {\"name\":\"srcAmount\",\"type\":\"uint256\"},{\"name\":\"dest\",\"type\":\"address\"}, {\"name\":\"destAddress\",\"type\":\"address\"},{\"name\":\"maxDestAmount\",\"type\":\"uint256\"},{\"name\":\"minConversionRate\",\"type\":\"uint256\"},{\"name\":\"walletId\",\"type\":\"address\"}],\"name\":\"trade\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"}"

  let exchange: KNDraftExchangeTransaction
  let address: Address

  var type: Web3RequestType {
    let minRate: BigInt = {
      guard let minRate = exchange.minRate else { return BigInt(0) }
      return minRate * BigInt(10).power(18 - exchange.to.decimals)
    }()
    let run = "web3.eth.abi.encodeFunctionCall(\(KNExchangeRequestEncode.abi), [\"\(exchange.from.address.description)\", \"\(exchange.amount.description)\", \"\(exchange.to.address.description)\", \"\(address.description)\", \"\(exchange.maxDestAmount.description)\", \"\(minRate.description)\", \"0x0000000000000000000000000000000000000000\"])"
    return .script(command: run)
  }
}

struct KNExchangeEventDataDecode: Web3Request {
  typealias Response = [String: String]

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameters([{\"name\": \"src\", \"type\": \"address\"}, {\"name\": \"dest\", \"type\": \"address\"}, {\"name\": \"srcAmount\", \"type\": \"uint256\"}, {\"name\": \"destAmount\", \"type\": \"uint256\"}], \"\(data)\")"
    return .script(command: run)
  }
}
