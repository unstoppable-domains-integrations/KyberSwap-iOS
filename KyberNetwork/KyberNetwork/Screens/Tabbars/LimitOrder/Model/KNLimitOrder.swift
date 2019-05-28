// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore

struct KNLimitOrder {
  let from: TokenObject
  let to: TokenObject
  let account: Account
  let sender: Address
  let srcAmount: BigInt
  let targetRate: BigInt
  let fee: Int
  let nonce: Int64
}
