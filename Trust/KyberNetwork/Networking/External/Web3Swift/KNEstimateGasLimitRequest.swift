// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import JSONRPCKit
import TrustKeystore
import BigInt

struct KNEstimateGasLimitRequest: JSONRPCKit.Request {
  typealias Response = String

  let transaction: SignTransaction

  var method: String {
    return "eth_estimateGas"
  }

  var parameters: Any? {
    return [
      [
        "from": transaction.account.address.description.lowercased(),
        "to": transaction.to?.description.lowercased() ?? "",
        "gasPrice": transaction.gasPrice.hexEncoded,
        "value": transaction.value.hexEncoded,
        "data": transaction.data.hexEncoded,
        ],
    ]
  }

  func response(from resultObject: Any) throws -> Response {
    if let response = resultObject as? Response {
      return response
    } else {
      throw CastError(actualValue: resultObject, expectedType: Response.self)
    }
  }
}
