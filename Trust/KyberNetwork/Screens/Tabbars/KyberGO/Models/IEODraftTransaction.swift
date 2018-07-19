// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class IEODraftTransaction {
  let token: TokenObject
  let ieo: IEOObject
  let amount: BigInt
  let wallet: KNWalletObject
  let gasPrice: BigInt
  let gasLimit: BigInt
  var v: String = ""
  var r: String = ""
  var s: String = ""
  var userID: BigInt = BigInt(-1)
  var nonce: Int = -1
  var estRate: BigInt?
  var minRate: BigInt?
  var maxDestAmount: BigInt?
  var data: Data?

  var expectedReceivedString: String? = ""

  init(
    token: TokenObject,
    ieo: IEOObject,
    amount: BigInt,
    wallet: KNWalletObject,
    gasPrice: BigInt,
    gasLimit: BigInt,
    estRate: BigInt?,
    minRate: BigInt? = nil,
    maxDestAmount: BigInt? = nil,
    expectedReceived: String? = nil
    ) {
    self.token = token
    self.ieo = ieo
    self.amount = amount
    self.wallet = wallet
    self.gasPrice = gasPrice
    self.gasLimit = gasLimit
    self.estRate = estRate
    self.minRate = minRate
    self.maxDestAmount = maxDestAmount
    self.expectedReceivedString = expectedReceived
  }

  func update(userID: Int) {
    self.userID = BigInt(userID)
  }

  func update(v: String, r: String, s: String) {
    self.v = v
    self.r = r
    self.s = s
  }

  var displayExpectedReceived: String {
    if let expectedReceived = self.expectedReceivedString {
      return "\(expectedReceived.prefix(10))"
    }
    return "\(self.expectedReceivedBigInt.fullString(decimals: self.ieo.tokenDecimals).prefix(10))"
  }

  fileprivate var expectedReceivedBigInt: BigInt {
    guard let rate = self.estRate else { return BigInt(0) }
    return rate * amount / BigInt(10).power(self.token.decimals)
  }
}
