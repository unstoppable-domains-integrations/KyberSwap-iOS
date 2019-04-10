// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNListAlertHeaderView: UITableViewHeaderFooterView {

  @IBOutlet weak var triggeredTextLabel: UILabel!

  func updateText(_ text: String) {
    self.triggeredTextLabel.text = text
  }
}
