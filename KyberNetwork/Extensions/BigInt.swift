// Copyright SIX DAY LLC. All rights reserved.

import BigInt

extension BigInt {
  var hexEncoded: String {
    return "0x" + String(self, radix: 16)
  }
}
