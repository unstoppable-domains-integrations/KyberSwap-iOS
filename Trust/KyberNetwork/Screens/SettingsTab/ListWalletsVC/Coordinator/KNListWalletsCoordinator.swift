// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNListWalletsCoordinatorDelegate: class {
  func listWalletsCoordinatorDidClickBack()
  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: Wallet)
  func listWalletsCoordinatorDidSelectWallet(_ wallet: Wallet)
}

class KNListWalletsCoordinator: Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession
  var coordinators: [Coordinator] = []

  weak var delegate: KNListWalletsCoordinatorDelegate?

  lazy var rootViewController: KNListWalletsViewController = {
    let controller = KNListWalletsViewController(delegate: self)
    controller.loadViewIfNeeded()
    return controller
  }()

  lazy var createWalletCoordinator: KNWalletImportingMainCoordinator = {
    let coordinator = KNWalletImportingMainCoordinator(keystore: self.session.keystore)
    coordinator.delegate = self
    return coordinator
  }()

  init(
    navigationController: UINavigationController,
    session: KNSession,
    delegate: KNListWalletsCoordinatorDelegate?
    ) {
    self.navigationController = navigationController
    self.session = session
    self.delegate = delegate
  }

  func start() {
    self.rootViewController.updateView(with: self.session.keystore.wallets, currentWallet: self.session.wallet)
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: false)
  }

  func updateNewSession(_ session: KNSession) {
    self.session = session
    self.session.keystore.wallets.forEach { wallet in
      if KNWalletStorage.shared.get(forPrimaryKey: wallet.address.description) == nil {
        let walletObject = KNWalletObject(address: wallet.address.description)
        KNWalletStorage.shared.add(wallets: [walletObject])
      }
    }
    self.rootViewController.updateView(with: self.session.keystore.wallets, currentWallet: self.session.wallet)
  }
}

extension KNListWalletsCoordinator: KNListWalletsViewControllerDelegate {
  func listWalletsViewControllerDidClickBackButton() {
    self.delegate?.listWalletsCoordinatorDidClickBack()
  }

  func listWalletsViewControllerDidSelectAddWallet() {
    //TODO: Add back button here
    self.createWalletCoordinator.start()
    self.navigationController.topViewController?.present(self.createWalletCoordinator.navigationController, animated: true, completion: nil)
  }

  func listWalletsViewControllerDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.listWalletsCoordinatorDidSelectWallet(wallet)
  }

  func listWalletsViewControllerDidSelectRemoveWallet(_ wallet: Wallet) {
    let alert = UIAlertController(title: "", message: "Do you want to remove this wallet?", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: { [unowned self] _ in
      self.delegate?.listWalletsCoordinatorDidSelectRemoveWallet(wallet)
    }))
    self.navigationController.topViewController?.present(alert, animated: true, completion: nil)
  }
}

extension KNListWalletsCoordinator: KNWalletImportingMainCoordinatorDelegate {
  func walletImportingMainDidImport(wallet: Wallet) {
    let walletObject = KNWalletObject(address: wallet.address.description)
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.rootViewController.updateView(with: self.session.keystore.wallets, currentWallet: self.session.wallet)
    self.navigationController.topViewController?.dismiss(animated: true, completion: nil)
  }
}
