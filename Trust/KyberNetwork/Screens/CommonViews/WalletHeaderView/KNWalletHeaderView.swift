// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNWalletHeaderViewDelegate: class {
  func walletHeaderScanQRCodePressed(wallet: KNWalletObject, sender: KNWalletHeaderView)
  func walletHeaderWalletListPressed(wallet: KNWalletObject, sender: KNWalletHeaderView)
}

class KNWalletHeaderView: XibLoaderView {
  @IBOutlet weak var walletIconImageView: UIImageView!
  @IBOutlet weak var walletInfoLabel: UILabel!

  weak var delegate: KNWalletHeaderViewDelegate?

  fileprivate var wallet: KNWalletObject?

  override func commonInit() {
    super.commonInit()
    self.backgroundColor = UIColor(hex: "0FAAA2")
    self.walletIconImageView.rounded(radius: self.walletIconImageView.frame.width / 2.0)
    self.walletInfoLabel.text = ""
  }

  func updateView(with wallet: KNWalletObject) {
    self.wallet = wallet
    self.walletIconImageView.image = UIImage(named: wallet.icon)
    self.walletInfoLabel.text = "\(wallet.address)\n\(wallet.name)"
  }

  @IBAction func scanQRCodePressed(_ sender: Any) {
    guard let wallet = self.wallet else { return }
    self.delegate?.walletHeaderScanQRCodePressed(wallet: wallet, sender: self)
  }

  @IBAction func walletListButtonPressed(_ sender: Any) {
    guard let wallet = self.wallet else { return }
    self.delegate?.walletHeaderWalletListPressed(wallet: wallet, sender: self)
  }
}
