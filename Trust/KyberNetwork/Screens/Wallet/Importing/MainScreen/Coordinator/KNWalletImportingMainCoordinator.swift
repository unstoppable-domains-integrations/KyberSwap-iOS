// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNWalletImportingMainCoordinator: Coordinator {

  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNWalletImportingMainViewController = {
    return KNWalletImportingMainViewController(delegate: self)
  }()

  lazy var importingKeystoreCoordinator: KNWalletImportingKeystoreCoordinator = {
    let coordinator = KNWalletImportingKeystoreCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
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
    self.addCoordinator(self.importingKeystoreCoordinator)
    self.importingKeystoreCoordinator.start()
  }

  func walletImportingMainScreenUserDidClickImportAddressByPrivateKey() {
  }
}

extension KNWalletImportingMainCoordinator: KNWalletImportingKeystoreCoordinatorDelegate {
  func walletImportKeystoreCoordinatorUserDidImport(wallet: Wallet) {
    NSLog("User did import wallet")
  }
}
