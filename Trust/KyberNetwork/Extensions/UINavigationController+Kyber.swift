// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UINavigationController {
  func applyStyle() {
    navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    navigationBar.isTranslucent = false
    navigationBar.shadowImage = UIImage()
    navigationBar.barTintColor = UIColor.Kyber.blue
    navigationBar.barStyle = UIBarStyle.black
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
  }
}
