// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNImportWalletCoordinatorDelegate: class {
  func importWalletCoordinatorDidImport(wallet: Wallet)
}

class KNImportWalletCoordinator: Coordinator {

  weak var delegate: KNImportWalletCoordinatorDelegate?
  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  fileprivate var importedWallet: Wallet?

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
    self.navigationController.popViewController(animated: true)
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
    let password = PasswordGenerator.generateRandom()
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
        print("Successfully import wallet")
        // add new wallet into database in case user exits app
        let walletObject = KNWalletObject(address: wallet.address.description)
        KNWalletStorage.shared.add(wallets: [walletObject])
        self.importedWallet = wallet
        let enterNameVC: KNEnterWalletNameViewController = {
          let viewModel = KNEnterWalletNameViewModel(walletObject: walletObject)
          let controller = KNEnterWalletNameViewController(viewModel: viewModel)
          controller.delegate = self
          controller.modalPresentationStyle = .overFullScreen
          return controller
        }()
        self.navigationController.topViewController?.present(enterNameVC, animated: false, completion: nil)
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }
}

extension KNImportWalletCoordinator: KNEnterWalletNameViewControllerDelegate {
  func enterWalletNameDidNext(sender: KNEnterWalletNameViewController, walletObject: KNWalletObject) {
    KNWalletStorage.shared.add(wallets: [walletObject])
    guard let wallet = self.importedWallet else { return }
    self.navigationController.topViewController?.dismiss(animated: false, completion: {
      self.delegate?.importWalletCoordinatorDidImport(wallet: wallet)
    })
  }
}
