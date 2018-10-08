// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNDataDetailsView: XibLoaderView {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!

  override func commonInit() {
    super.commonInit()
    self.titleLabel.text = ""
    self.subtitleLabel.text = ""
  }

  func updateView(with title: String, subTitle: String) {
    self.titleLabel.text = title
    self.subtitleLabel.text = subTitle
    self.layoutIfNeeded()
  }

  func updateView(with titleAttributed: NSAttributedString, subTitleAttributed: NSAttributedString) {
    self.titleLabel.attributedText = titleAttributed
    self.subtitleLabel.attributedText = subTitleAttributed
    self.layoutIfNeeded()
  }
}
