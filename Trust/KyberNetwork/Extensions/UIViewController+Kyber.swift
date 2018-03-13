// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIViewController {
  func applyBaseGradientBackground() {
    let colors = [UIColor.Kyber.cyan, UIColor.Kyber.green, UIColor.Kyber.teal]
    self.view.applyTopRightBottomLeftGradient(with: colors)
  }
}
