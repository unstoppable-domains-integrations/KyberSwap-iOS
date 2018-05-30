// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UINavigationController {
  func applyStyle() {
    navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    navigationBar.isTranslucent = false
    navigationBar.shadowImage = UIImage()
    navigationBar.barTintColor = UIColor(hex: "31CB9E")
    navigationBar.barStyle = UIBarStyle.black
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
  }

  public func pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    pushViewController(viewController, animated: animated)
    CATransaction.commit()
  }

  public func popViewController(animated: Bool, completion: (() -> ())?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    popViewController(animated: animated)
    CATransaction.commit()
  }
}
