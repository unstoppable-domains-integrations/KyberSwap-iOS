// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import JSONRPCKit
import APIKit

struct KNGetTransactionReceiptRequest: JSONRPCKit.Request {
  typealias Response = KNTransactionReceipt

  let hash: String

  var method: String {
    return "eth_getTransactionReceipt"
  }

  var parameters: Any? {
    return [hash]
  }

  func response(from resultObject: Any) throws -> Response {
    guard
      let dict = resultObject as? JSONDictionary,
      let receipt = KNTransactionReceipt.from(dict)
      else {
        throw CastError(actualValue: resultObject, expectedType: Response.self)
    }
    return receipt
  }
}
