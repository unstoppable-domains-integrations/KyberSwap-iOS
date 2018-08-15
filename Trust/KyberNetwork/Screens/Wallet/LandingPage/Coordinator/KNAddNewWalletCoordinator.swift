// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import BigInt

protocol KNAddNewWalletCoordinatorDelegate: class {
  func addNewWalletCoordinator(add wallet: Wallet)
}

class KNAddNewWalletCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  fileprivate var keystore: Keystore

  fileprivate var newWallet: Wallet?
  fileprivate var isCreate: Bool = false

  weak var delegate: KNAddNewWalletCoordinatorDelegate?

  lazy var createWalletCoordinator: KNCreateWalletCoordinator = {
    let coordinator = KNCreateWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore,
      newWallet: nil,
      name: nil
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var importWalletCoordinator: KNImportWalletCoordinator = {
    let coordinator = KNImportWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    keystore: Keystore
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    let rootViewController = UIViewController()
    rootViewController.view.backgroundColor = UIColor.clear
    self.navigationController.viewControllers = [rootViewController]
    self.navigationController.modalPresentationStyle = .overCurrentContext
    self.navigationController.modalTransitionStyle = .crossDissolve
    self.keystore = keystore
  }

  lazy var alertController: UIAlertController = {
    let controller = UIAlertController(
      title: nil,
      message: "Add new wallet?",
      preferredStyle: .actionSheet
    )
    controller.addAction(UIAlertAction(title: "Create a new wallet", style: .default, handler: { _ in
      self.createNewWallet()
    }))
    controller.addAction(UIAlertAction(title: "Import a wallet", style: .default, handler: { _ in
      self.importAWallet()
    }))
    controller.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
      self.navigationController.dismiss(animated: false, completion: nil)
    }))
    return controller
  }()

  func start() {
    self.navigationController.present(self.alertController, animated: true, completion: nil)
  }

  fileprivate func createNewWallet() {
    self.isCreate = true
    self.newWallet = nil
    self.createWalletCoordinator.updateNewWallet(nil)
    self.createWalletCoordinator.start()
  }

  fileprivate func importAWallet() {
    self.isCreate = false
    self.newWallet = nil
    self.importWalletCoordinator.start()
  }
}

extension KNAddNewWalletCoordinator: KNCreateWalletCoordinatorDelegate {
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?, name: String?) {
    guard let wallet = wallet else { return }
    self.navigationController.dismiss(animated: true) {
      let walletObject = KNWalletObject(
        address: wallet.address.description,
        name: name ?? "Untitled"
      )
      KNWalletStorage.shared.add(wallets: [walletObject])
      self.delegate?.addNewWalletCoordinator(add: wallet)
    }
  }
}

extension KNAddNewWalletCoordinator: KNImportWalletCoordinatorDelegate {
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?) {
    self.navigationController.dismiss(animated: true) {
      let walletObject = KNWalletObject(
        address: wallet.address.description,
        name: name ?? "Untitled"
      )
      KNWalletStorage.shared.add(wallets: [walletObject])
      self.delegate?.addNewWalletCoordinator(add: wallet)
    }
  }

  func importWalletCoordinatorDidClose() {
    self.navigationController.dismiss(animated: true, completion: nil)
  }
}
