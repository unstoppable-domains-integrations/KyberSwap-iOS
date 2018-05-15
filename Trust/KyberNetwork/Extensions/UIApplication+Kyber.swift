// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIApplication {
  var statusBarView: UIView? {
    if responds(to: Selector("statusBar")) {
      return value(forKey: "statusBar") as? UIView
    }
    return nil
  }
}
