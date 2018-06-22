// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNSearchTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tokenSymbolLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenNameLabel.text = ""
    self.tokenSymbolLabel.text = ""
    self.textLabel?.textColor = UIColor(hex: "5A5E67")
    self.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
  }

  func updateCell(with token: TokenObject) {
    //TODO: remove default value
    self.iconImageView.image = UIImage(named: token.icon) ?? UIImage(named: "accounts_active")
    self.tokenSymbolLabel.text = token.symbol
    self.tokenNameLabel.text = token.name
    self.layoutIfNeeded()
  }
}
