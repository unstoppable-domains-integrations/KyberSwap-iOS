// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNImportWalletCoordinatorDelegate: class {
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?)
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
    self.rootViewController.resetUIs()
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop(completion: (() -> Void)? = nil) {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.importWalletCoordinatorDidClose()
      completion?()
    }
  }
}

extension KNImportWalletCoordinator: KNImportWalletViewControllerDelegate {
  func importWalletViewController(_ controller: KNImportWalletViewController, run event: KNImportWalletViewEvent) {
    switch event {
    case .back:
      self.stop()
    case .importJSON(let json, let password, let name):
      self.importWallet(with: .keystore(string: json, password: password), name: name)
    case .importPrivateKey(let privateKey, let name):
      self.importWallet(with: .privateKey(privateKey: privateKey), name: name)
    case .importSeeds(let seeds, let name):
      self.importWallet(with: .mnemonic(words: seeds, password: ""), name: name)
    }
  }

  fileprivate func importWallet(with type: ImportType, name: String?) {
    self.navigationController.topViewController?.displayLoading(text: "\(NSLocalizedString("importing.wallet", value: "Importing wallet", comment: ""))...", animated: true)
    self.keystore.importWallet(type: type) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.topViewController?.hideLoading()
      switch result {
      case .success(let wallet):
        self.navigationController.showSuccessTopBannerMessage(
          with: NSLocalizedString("wallet.imported", value: "Wallet Imported", comment: ""),
          message: NSLocalizedString("you.have.successfully.imported.a.wallet", value: "You have successfully imported a wallet", comment: ""),
          time: 1.5
        )
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5, execute: {
          let walletName: String = {
            if name == nil || name?.isEmpty == true { return "Untitled" }
            return name ?? "Untitled"
          }()
          self.delegate?.importWalletCoordinatorDidImport(wallet: wallet, name: walletName)
        })
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }
}
