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

  func stop(completion: @escaping () -> Void) {
    self.rootViewController.dismiss(animated: true, completion: completion)
  }

  func updateNewSession(_ session: KNSession) {
    self.session = session
    self.rootViewController.updateView(with: self.session.keystore.wallets, currentWallet: self.session.wallet)
  }
}

extension KNListWalletsCoordinator: KNListWalletsViewControllerDelegate {
  func listWalletsViewControllerDidClickBackButton() {
    self.delegate?.listWalletsCoordinatorDidClickBack()
  }

  func listWalletsViewControllerDidSelectAddWallet() {
    //TODO: Show add wallet
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
