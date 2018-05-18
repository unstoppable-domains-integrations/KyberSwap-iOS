// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNListWalletsTableViewCell: UITableViewCell {

  @IBOutlet weak var walletIconImageView: UIImageView!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var walletAddressLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.walletNameLabel.text = "Untitled".toBeLocalised()
    self.walletAddressLabel.text = ""
  }

  func updateCell(with wallet: KNWalletObject) {
    self.walletNameLabel.text = wallet.name
    self.walletAddressLabel.text = wallet.address
    if let image = UIImage(named: wallet.icon) {
      self.walletIconImageView.image = image
    } else {
      self.walletIconImageView.image = UIImage(named: "settings-wallet")
    }
    self.layoutIfNeeded()
  }
}
