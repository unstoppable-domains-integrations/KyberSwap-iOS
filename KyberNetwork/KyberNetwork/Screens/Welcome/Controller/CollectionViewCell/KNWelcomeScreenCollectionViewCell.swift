// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNWelcomeScreenCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kWelcomeScreenCollectionViewCellID"
  static let height: CGFloat = 400

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subTitleLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = .clear
    self.titleLabel.textColor = .white
    self.subTitleLabel.textColor = .white
    // Initialization code
  }

  func updateCell(with data: KNWelcomeScreenViewModel.KNWelcomeData) {
    self.imageView.image = UIImage(named: data.icon)
    self.titleLabel.text = data.title
    self.titleLabel.addLetterSpacing()
    self.subTitleLabel.text = data.subtitle
    self.subTitleLabel.addLetterSpacing()
    self.layoutSubviews()
  }
}
