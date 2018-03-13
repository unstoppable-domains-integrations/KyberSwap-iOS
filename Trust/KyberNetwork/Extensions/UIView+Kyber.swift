// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIView {

  func rounded(color: UIColor, width: CGFloat, radius: CGFloat) {
    self.layer.borderColor = color.cgColor
    self.layer.borderWidth = width
    self.layer.cornerRadius = radius
    self.clipsToBounds = true
  }
}
