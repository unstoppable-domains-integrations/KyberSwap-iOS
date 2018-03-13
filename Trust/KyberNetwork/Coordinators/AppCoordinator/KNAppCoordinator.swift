// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNAppCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  let window: UIWindow
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  lazy var splashScreenCoordinator: KNSplashScreenCoordinator = {
    return KNSplashScreenCoordinator()
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    window: UIWindow,
    keystore: Keystore) {
    self.navigationController = navigationController
    self.window = window
    self.keystore = keystore
    super.init()
    self.window.rootViewController = self.navigationController
    self.window.makeKeyAndVisible()
  }

  func start() {
    self.addCoordinator(self.splashScreenCoordinator)
    self.splashScreenCoordinator.start()
  }

}
