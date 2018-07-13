// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNWelcomeScreenCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kWelcomeScreenCollectionViewCellID"
  static let height: CGFloat = 300

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subTitleLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.imageView.rounded(radius: self.imageView.frame.width / 2.0)
  }

  func updateCell(with data: KNWelcomeScreenViewModel.KNWelcomeData) {
    self.imageView.image = UIImage(named: data.icon)
    self.titleLabel.text = data.title
    self.subTitleLabel.text = data.subtitle
    self.layoutSubviews()
  }
}
