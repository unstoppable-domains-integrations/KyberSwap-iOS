// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNWalletImportingMainCoordinator: Coordinator {

  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNWalletImportingMainViewController = {
    return KNWalletImportingMainViewController(delegate: self)
  }()

  init(navigationController: UINavigationController = UINavigationController(),
       keystore: Keystore) {
    self.navigationController = navigationController
    self.keystore = keystore
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() { }
}

extension KNWalletImportingMainCoordinator: KNWalletImportingMainViewControllerDelegate {
  func walletImportingMainScreenUserDidClickImportAddressByKeystore() {
  }

  func walletImportingMainScreenUserDidClickImportAddressByPrivateKey() {
  }
}
