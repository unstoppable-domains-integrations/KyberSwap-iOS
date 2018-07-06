// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNContactTableViewCellModel {
  let contact: KNContact

  init(contact: KNContact) { self.contact = contact }

  var displayedName: String { return self.contact.name }
  var displayedAddress: String {
    return "\(self.contact.address.prefix(8))....\(self.contact.address.suffix(6))"
  }
}

class KNContactTableViewCell: UITableViewCell {

  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var contactAddressLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.contactNameLabel.text = ""
    self.contactAddressLabel.text = ""
  }

  func update(with viewModel: KNContactTableViewCellModel) {
    self.contactNameLabel.text = viewModel.displayedName
    self.contactAddressLabel.text = viewModel.displayedAddress
  }
}
