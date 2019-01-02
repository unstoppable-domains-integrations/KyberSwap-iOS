// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UITextField {
  func addPlaceholderSpacing(value: CGFloat = 0.0) {
    let attributedString = NSMutableAttributedString(string: self.placeholder ?? "")
    attributedString.addAttribute(NSAttributedStringKey.kern, value: value, range: NSRange(location: 0, length: (self.placeholder ?? "").count))
    self.attributedPlaceholder = attributedString
  }
}
