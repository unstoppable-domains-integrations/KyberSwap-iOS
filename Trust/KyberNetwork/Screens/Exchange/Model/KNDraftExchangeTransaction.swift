// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt

struct KNDraftExchangeTransaction {
  let from: KNToken
  let to: KNToken
  let amount: BigInt
  let maxDestAmount: BigInt
  let minRate: BigInt?
  let gasPrice: BigInt?
  let gasLimit: BigInt?
}
