// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNWalletImportingKeystoreCoordinatorDelegate: class {
  func walletImportKeystoreCoordinatorUserDidImport(wallet: Wallet)
}

class KNWalletImportingKeystoreCoordinator: Coordinator {

  let navigationController: UINavigationController
  let keystore: Keystore
  weak var delegate: KNWalletImportingKeystoreCoordinatorDelegate?
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNWalletImportingKeystoreViewController = {
    return KNWalletImportingKeystoreViewController(delegate: self)
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

extension KNWalletImportingKeystoreCoordinator: KNWalletImportingKeystoreViewControllerDelegate {
  func walletImportingKeystoreDidImport(keystore: String, password: String) {
    self.navigationController.topViewController?.displayLoading(text: "Importing address ...")
    let importType = ImportType.keystore(string: keystore, password: password)
    self.keystore.importWallet(type: importType) { [weak self] (result) in
      guard let `self` = self else { return }
      self.navigationController.topViewController?.hideLoading()
      switch result {
      case .success(let wallet):
        if isDebug { NSLog("Successfully add address via keystore") }
        self.delegate?.walletImportKeystoreCoordinatorUserDidImport(wallet: wallet)
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }

  func walletImportingKeystoreDidCancel() {
    self.stop()
  }
}
