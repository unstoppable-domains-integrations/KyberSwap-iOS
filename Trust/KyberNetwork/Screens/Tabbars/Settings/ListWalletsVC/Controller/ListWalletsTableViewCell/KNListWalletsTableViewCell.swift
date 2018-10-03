// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustCore

class KNListWalletsTableViewCell: UITableViewCell {

  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var walletAddressLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.walletNameLabel.text = "Untitled"
    self.walletAddressLabel.text = ""
  }

  func updateCell(with wallet: KNWalletObject, id: Int) {
    self.walletNameLabel.text = wallet.name
    self.walletAddressLabel.text = wallet.address
    self.backgroundColor = id % 2 == 0 ? UIColor.clear : UIColor.white
    self.layoutIfNeeded()
  }
}
