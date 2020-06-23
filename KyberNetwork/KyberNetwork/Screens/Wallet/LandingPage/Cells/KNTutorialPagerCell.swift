// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import FSPagerView

class KNTutorialPagerCell: FSPagerViewCell {
  @IBOutlet weak var headerTitleLabel: UILabel!
  @IBOutlet weak var contentContainerView: UIView!
  @IBOutlet weak var contentImageView: UIImageView!
  @IBOutlet weak var contentLabel: UILabel!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.contentView.backgroundColor = UIColor.clear
    self.backgroundColor = UIColor.clear
    self.contentView.layer.shadowColor = UIColor.clear.cgColor
    self.contentView.layer.shadowRadius = 0
    self.contentView.layer.shadowOpacity = 0.0
    self.contentView.layer.shadowOffset = .zero
  }
  override func awakeFromNib() {
    super.awakeFromNib()
    self.contentContainerView.rounded()
  }

}
