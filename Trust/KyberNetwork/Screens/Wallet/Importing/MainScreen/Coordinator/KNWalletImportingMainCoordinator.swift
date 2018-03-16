// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNWalletImportingMainCoordinatorDelegate: class {
  func walletImportingMainDidImport(wallet: Wallet)
}

class KNWalletImportingMainCoordinator: Coordinator {

  weak var delegate: KNWalletImportingMainCoordinatorDelegate?

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

  lazy var importingPrivateKeyCoordinator: KNWalletImportingPrivateKeyCoordinator = {
    let coordinator = KNWalletImportingPrivateKeyCoordinator(
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
    self.addCoordinator(self.importingPrivateKeyCoordinator)
    self.importingPrivateKeyCoordinator.start()
  }
}

extension KNWalletImportingMainCoordinator: KNWalletImportingKeystoreCoordinatorDelegate {
  func walletImportKeystoreCoordinatorUserDidImport(wallet: Wallet) {
    self.importingKeystoreCoordinator.stop {
      self.removeCoordinator(self.importingKeystoreCoordinator)
      self.delegate?.walletImportingMainDidImport(wallet: wallet)
    }
  }
}

extension KNWalletImportingMainCoordinator: KNWalletImportingPrivateKeyCoordinatorDelegate {
  func walletImportingPrivateKeyDidImport(wallet: Wallet) {
    self.importingPrivateKeyCoordinator.stop {
      self.removeCoordinator(self.importingPrivateKeyCoordinator)
      self.delegate?.walletImportingMainDidImport(wallet: wallet)
    }
  }
}
