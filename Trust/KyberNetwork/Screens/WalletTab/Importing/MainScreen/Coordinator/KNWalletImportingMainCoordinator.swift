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

  lazy var createPasswordController: KNCreatePasswordViewController = {
    let controller = KNCreatePasswordViewController(delegate: self)
    controller.modalPresentationStyle = .overFullScreen
    return controller
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

  func walletImportingMainScreenCreateWalletPressed() {
    self.navigationController.topViewController?.present(self.createPasswordController, animated: true, completion: nil)
  }

  // MARK: DEBUG only
  func walletImportingMainScreenUserDidClickDebug() {
    let debugVC = KNDebugMenuViewController()
    self.navigationController.topViewController?.present(debugVC, animated: true, completion: nil)
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

extension KNWalletImportingMainCoordinator: KNCreatePasswordViewControllerDelegate {
  func createPasswordUserDidFinish(_ password: String) {
    self.navigationController.topViewController?.displayLoading(text: "Creating Wallet...", animated: true)
    self.keystore.createAccount(with: password) { [weak self] result in
      self?.navigationController.topViewController?.hideLoading()
      switch result {
      case .success(let account):
        let wallet = Wallet(type: .real(account))
        self?.delegate?.walletImportingMainDidImport(wallet: wallet)
      case .failure(let error):
        self?.navigationController.topViewController?.displayError(error: error)
      }
    }
  }
}
