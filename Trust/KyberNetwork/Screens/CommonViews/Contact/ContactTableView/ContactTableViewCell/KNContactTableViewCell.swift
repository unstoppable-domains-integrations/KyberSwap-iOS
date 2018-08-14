// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustCore

struct KNContactTableViewCellModel {
  let contact: KNContact

  init(contact: KNContact) { self.contact = contact }

  var addressImage: UIImage? {
    guard let data = Address(string: self.contact.address)?.data else { return nil }
    return UIImage.generateImage(with: 32, hash: data)
  }
  var displayedName: String { return self.contact.name }
  var displayedAddress: String {
    return "\(self.contact.address.prefix(7))...\(self.contact.address.suffix(4))"
  }
}

class KNContactTableViewCell: UITableViewCell {

  static let height: CGFloat = 60

  @IBOutlet weak var addressImageView: UIImageView!
  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var contactAddressLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.contactNameLabel.text = ""
    self.contactAddressLabel.text = ""
    self.addressImageView.rounded(radius: self.addressImageView.frame.height / 2.0)
  }

  func update(with viewModel: KNContactTableViewCellModel) {
    self.addressImageView.image = viewModel.addressImage
    self.contactNameLabel.text = viewModel.displayedName
    self.contactAddressLabel.text = viewModel.displayedAddress
    self.layoutIfNeeded()
  }
}
