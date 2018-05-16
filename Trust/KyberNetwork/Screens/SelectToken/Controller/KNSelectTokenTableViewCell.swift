// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNSelectTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var balanceLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = UIColor.clear
    self.textLabel?.textColor = UIColor.white
    self.textLabel?.font = self.textLabel?.font.withSize(16)
    self.balanceLabel.textColor = UIColor.white
    self.balanceLabel.text = ""
    self.selectedBackgroundView = UIView()
  }

  func updateCell(with token: TokenObject, balance: Balance) {
    self.imageView?.image = UIImage(named: token.icon)
    self.textLabel?.text = token.display
    self.balanceLabel.text = "\(balance.amountShort)"
  }
}
