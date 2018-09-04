// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNWalletQRCodeViewModel {
  let wallet: KNWalletObject

  init(wallet: KNWalletObject) {
    self.wallet = wallet
  }

  var displayedAddress: String {
    return self.address
  }

  var address: String { return self.wallet.address }

  var shareText: String {
    return "\(self.displayedAddress)"
  }

  var copyAddressBtnTitle: String {
    return "Copy".toBeLocalised()
  }

  var shareBtnTitle: String {
    return "Share".toBeLocalised()
  }

  var navigationTitle: String {
    return self.wallet.name
  }
}
