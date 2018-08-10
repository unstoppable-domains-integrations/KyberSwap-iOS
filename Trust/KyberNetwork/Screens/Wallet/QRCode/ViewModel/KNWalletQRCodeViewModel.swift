// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNWalletQRCodeViewModel {
  let wallet: KNWalletObject

  init(wallet: KNWalletObject) {
    self.wallet = wallet
  }

  var displayedAddress: String {
    return String(self.address.prefix(20)) + "......" + String(self.address.suffix(8))
  }

  var address: String { return self.wallet.address }

  var shareText: String {
    return "\(self.displayedAddress)"
  }

  var copyAddressBtnTitle: String {
    return "Copy".toBeLocalised().uppercased()
  }

  var shareBtnTitle: String {
    return "Share".toBeLocalised().uppercased()
  }

  var navigationTitle: String {
    return self.wallet.name
  }
}
