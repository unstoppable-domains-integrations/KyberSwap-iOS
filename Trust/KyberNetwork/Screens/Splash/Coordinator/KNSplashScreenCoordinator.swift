// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNSplashScreenCoordinator: Coordinator {

  let splashWindow: UIWindow

  var coordinators: [Coordinator] = []

  lazy var splashVC: KNSplashScreenViewController = {
    return KNSplashScreenViewController()
  }()

  init() {
    self.splashWindow = UIWindow()
    self.splashWindow.windowLevel = UIWindowLevelStatusBar + 2.0
  }

  func start() {
    self.splashWindow.rootViewController = self.splashVC
    self.splashWindow.makeKeyAndVisible()
    self.splashWindow.isHidden = false
    Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
      self.stop { }
    }
  }

  func stop(completion: @escaping () -> Void) {
    self.splashVC.moveSplashLogoAnimation {
      self.splashWindow.isHidden = true
    }
  }
}
