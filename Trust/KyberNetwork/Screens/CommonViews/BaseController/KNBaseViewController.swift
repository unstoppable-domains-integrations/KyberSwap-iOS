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

  override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    if item.tag == 0 {
      // Balance tab
      tabBar.tintColor = UIColor.Kyber.lightSeaGreen
    } else if item.tag == 1 {
      // KyberSwap tab
      tabBar.tintColor = UIColor.Kyber.merigold
    } else if item.tag == 2 {
      // KyberGO tab
      tabBar.tintColor = UIColor.Kyber.sapphire
    } else if item.tag == 3 {
      // Settings tab
      tabBar.tintColor = UIColor.black
    }
  }
}

class KNNavigationController: UINavigationController {
  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
