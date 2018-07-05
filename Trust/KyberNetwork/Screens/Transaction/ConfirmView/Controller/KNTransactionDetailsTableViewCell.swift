// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNTransactionDetailsTableViewCell: UITableViewCell {

  @IBOutlet weak var fieldLabel: UILabel!
  @IBOutlet weak var detailsDataLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.detailsDataLabel.text = ""
    self.detailsDataLabel.textColor = .black
    self.backgroundColor = .clear
    self.fieldLabel.text = ""
    self.fieldLabel.textColor = .black
  }

  func updateCell(text: String, details: String) {
    self.fieldLabel.text = text
    self.detailsDataLabel.text = details
    self.layoutIfNeeded()
  }
}
