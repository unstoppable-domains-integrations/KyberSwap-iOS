// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNWalletImportingPrivateKeyCoordinatorDelegate: class {
  func walletImportingPrivateKeyDidImport(wallet: Wallet)
}

class KNWalletImportingPrivateKeyCoordinator: Coordinator {

  let navigationController: UINavigationController
  let keystore: Keystore
  weak var delegate: KNWalletImportingPrivateKeyCoordinatorDelegate?
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNWalletImportingPrivateKeyViewController = {
    return KNWalletImportingPrivateKeyViewController(delegate: self)
  }()

  init(navigationController: UINavigationController,
       keystore: Keystore) {
    self.navigationController = navigationController
    self.keystore = keystore
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }
}

extension KNWalletImportingPrivateKeyCoordinator: KNWalletImportingPrivateKeyViewControllerDelegate {
  func walletImportingPrivateKeyDidImport(privateKey: String) {
    self.navigationController.topViewController?.displayLoading(text: "Importing address ...")
    let importType = ImportType.privateKey(privateKey: privateKey)
    self.keystore.importWallet(type: importType) { [weak self] (result) in
      guard let `self` = self else { return }
      self.navigationController.topViewController?.hideLoading()
      switch result {
      case .success(let wallet):
        if isDebug { NSLog("Successfully add address via private key") }
        self.delegate?.walletImportingPrivateKeyDidImport(wallet: wallet)
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }

  func walletImportingPrivateKeyDidCancel() {
    self.stop()
  }
}
