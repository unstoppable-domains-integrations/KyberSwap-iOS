// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNWalletQRCodeViewModel {
  let wallet: KNWalletObject

  init(wallet: KNWalletObject) {
    self.wallet = wallet
  }

  var address: String {
    return self.wallet.address
  }

  var shareText: String {
    return "My address: \(self.address)"
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
