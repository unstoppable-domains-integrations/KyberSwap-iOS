// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNWalletCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession
  let balanceCoordinator: KNBalanceCoordinator

  weak var delegate: KNSessionDelegate?

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNWalletViewController = {
    return KNWalletViewController(delegate: self)
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession,
    balanceCoordinator: KNBalanceCoordinator
    ) {
    self.navigationController = navigationController
    self.navigationController.applyStyle()
    self.session = session
    self.balanceCoordinator = balanceCoordinator
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
  }
}

extension KNWalletCoordinator: KNWalletViewControllerDelegate {
  func walletViewControllerDidExit() {
    self.delegate?.userDidClickExitSession()
  }
}
