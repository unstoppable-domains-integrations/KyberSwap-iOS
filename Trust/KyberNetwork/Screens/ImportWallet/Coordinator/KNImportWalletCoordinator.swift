// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNImportWalletCoordinatorDelegate: class {
  func importWalletCoordinatorDidImport(wallet: Wallet)
  func importWalletCoordinatorDidClose()
}

class KNImportWalletCoordinator: Coordinator {

  weak var delegate: KNImportWalletCoordinatorDelegate?
  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNImportWalletViewController = {
    let controller = KNImportWalletViewController()
    controller.delegate = self
    controller.loadViewIfNeeded()
    return controller
  }()

  init(
    navigationController: UINavigationController,
    keystore: Keystore
  ) {
    self.navigationController = navigationController
    self.keystore = keystore
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.importWalletCoordinatorDidClose()
    }
  }
}

extension KNImportWalletCoordinator: KNImportWalletViewControllerDelegate {
  func importWalletViewControllerDidBack(sender: KNImportWalletViewController) {
    self.stop()
  }

  func importWalletViewControllerDidNext(sender: KNImportWalletViewController, json: String, password: String) {
    let type = ImportType.keystore(string: json, password: password)
    self.importWallet(with: type)
  }

  func importWalletViewControllerDidNext(sender: KNImportWalletViewController, privateKey: String) {
    let type = ImportType.privateKey(privateKey: privateKey)
    self.importWallet(with: type)
  }

  func importWalletViewControllerDidNext(sender: KNImportWalletViewController, seeds: [String]) {
    let password = "1234567890"//PasswordGenerator.generateRandom()
    let type = ImportType.mnemonic(words: seeds, password: password)
    self.importWallet(with: type)
  }

  fileprivate func importWallet(with type: ImportType) {
    self.navigationController.topViewController?.displayLoading(text: "Importing Wallet...", animated: true)
    self.keystore.importWallet(type: type) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.topViewController?.hideLoading()
      switch result {
      case .success(let wallet):
        self.delegate?.importWalletCoordinatorDidImport(wallet: wallet)
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }
}
