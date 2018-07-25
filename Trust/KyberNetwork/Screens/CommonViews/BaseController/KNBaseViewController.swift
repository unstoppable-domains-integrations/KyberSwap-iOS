// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNBaseViewController: UIViewController {

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NSLog("Did present: \(self.className)")
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NSLog("Did dismiss: \(self.className)")
  }
}

class KNTabBarController: UITabBarController {
  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}

class KNNavigationController: UINavigationController {
  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
