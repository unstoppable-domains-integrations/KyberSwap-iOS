// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNEligibleTokensTableViewCell: UITableViewCell {

  @IBOutlet var tokenSymbols: [UILabel]!
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.tokenSymbols.forEach({ $0.text = "" })
  }

  func updateCell(with symbols: [String]) {
    self.tokenSymbols.forEach({ $0.text = $0.tag >= symbols.count ? nil : symbols[$0.tag] })
    self.layoutIfNeeded()
  }
}
