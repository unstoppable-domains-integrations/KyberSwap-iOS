// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import JSONRPCKit
import TrustKeystore
import BigInt

struct KNEstimateGasLimitRequest: JSONRPCKit.Request {
  typealias Response = String

  let from: Address
  let to: Address?
  let value: BigInt
  let data: Data
  let gasPrice: BigInt

  var method: String {
    return "eth_estimateGas"
  }

  var parameters: Any? {
    return [
      [
        "from": from.description.lowercased(),
        "to": to?.description.lowercased() ?? "0x",
        "gasPrice": gasPrice.hexEncoded,
        "value": value.hexEncoded,
        "data": data.hexEncoded,
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
