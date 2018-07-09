// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNListWalletsCoordinatorDelegate: class {
  func listWalletsCoordinatorDidClickBack()
  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: Wallet)
  func listWalletsCoordinatorDidSelectWallet(_ wallet: Wallet)
  func listWalletsCoordinatorDidUpdateWalletObjects()
}

class KNListWalletsCoordinator: Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession
  var coordinators: [Coordinator] = []

  weak var delegate: KNListWalletsCoordinatorDelegate?

  lazy var rootViewController: KNListWalletsViewController = {
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() })!
    let viewModel = KNListWalletsViewModel(listWallets: listWallets, curWallet: curWallet)
    let controller = KNListWalletsViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
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
    self.syncWalletData()
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() })!
    self.rootViewController.updateView(
      with: listWallets,
      currentWallet: curWallet
    )
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: false)
  }

  func updateNewSession(_ session: KNSession) {
    self.session = session
    self.syncWalletData()
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() })!
    self.rootViewController.updateView(
      with: listWallets,
      currentWallet: curWallet
    )
  }

  fileprivate func syncWalletData() {
    let walletObjects = self.session.keystore.wallets.filter {
      return KNWalletStorage.shared.get(forPrimaryKey: $0.address.description) == nil
    }.map { return KNWalletObject(address: $0.address.description) }
    KNWalletStorage.shared.add(wallets: walletObjects)
  }
}

extension KNListWalletsCoordinator: KNListWalletsViewControllerDelegate {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent) {
    switch event {
    case .close:
      self.listWalletsViewControllerDidClickBackButton()
    case .select(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
        return
      }
      self.listWalletsViewControllerDidSelectWallet(wal)
    case .remove(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
        return
      }
      self.listWalletsViewControllerDidSelectRemoveWallet(wal)
    case .edit(let wallet):
      let viewModel = KNEnterWalletNameViewModel(walletObject: wallet, isEditing: true)
      let controller = KNEnterWalletNameViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.modalTransitionStyle = .crossDissolve
      controller.modalPresentationStyle = .overCurrentContext
      controller.delegate = self
      self.navigationController.present(controller, animated: true, completion: nil)
    }
  }

  fileprivate func listWalletsViewControllerDidClickBackButton() {
    self.delegate?.listWalletsCoordinatorDidClickBack()
  }

  fileprivate func listWalletsViewControllerDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.listWalletsCoordinatorDidSelectWallet(wallet)
  }

  fileprivate func listWalletsViewControllerDidSelectRemoveWallet(_ wallet: Wallet) {
    let alert = UIAlertController(title: "", message: "Do you want to remove this wallet?", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: { [unowned self] _ in
      self.delegate?.listWalletsCoordinatorDidSelectRemoveWallet(wallet)
    }))
    self.navigationController.topViewController?.present(alert, animated: true, completion: nil)
  }
}

extension KNListWalletsCoordinator: KNEnterWalletNameViewControllerDelegate {
  func enterWalletNameDidNext(sender: KNEnterWalletNameViewController, walletObject: KNWalletObject) {
    KNWalletStorage.shared.update(wallets: [walletObject])
    let wallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = wallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() })!
    self.rootViewController.updateView(
      with: KNWalletStorage.shared.wallets,
      currentWallet: curWallet
    )
    self.delegate?.listWalletsCoordinatorDidUpdateWalletObjects()
  }
}
