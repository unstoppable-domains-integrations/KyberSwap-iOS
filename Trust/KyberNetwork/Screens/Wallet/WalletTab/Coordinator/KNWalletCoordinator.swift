// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNWalletCoordinatorDelegate: class {
  func walletCoordinatorDidClickExit()
  func walletCoordinatorDidClickExchange(token: KNToken)
  func walletCoordinatorDidClickTransfer(token: KNToken)
  func walletCoordinatorDidClickReceive(token: KNToken)
}

class KNWalletCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession
  let balanceCoordinator: KNBalanceCoordinator

  weak var delegate: KNWalletCoordinatorDelegate?

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNWalletViewController = {
    let controller = KNWalletViewController(delegate: self)
    controller.loadViewIfNeeded()
    return controller
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

// Update from appcoordinator
extension KNWalletCoordinator {
  func tokenBalancesDidUpdateNotification(_ sender: Any) {
    self.rootViewController.coordinatorUpdateTokenBalances(self.balanceCoordinator.otherTokensBalance)
    self.exchangeRateDidUpdateNotification(sender)
  }

  func ethBalanceDidUpdateNotification(_ sender: Any) {
    if let ethToken = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.isETH }) {
      self.rootViewController.coordinatorUpdateTokenBalances([ethToken.address: self.balanceCoordinator.ethBalance])
    }
    self.exchangeRateDidUpdateNotification(sender)
  }

  func exchangeRateDidUpdateNotification(_ sender: Any) {
    self.rootViewController.coordinatorUpdateBalanceInETHAndUSD(
      ethBalance: self.balanceCoordinator.totalBalanceInETH,
      usdBalance: self.balanceCoordinator.totalBalanceInUSD
    )
  }
}

extension KNWalletCoordinator: KNWalletViewControllerDelegate {
  func walletViewControllerDidExit() {
    self.stop()
    self.delegate?.walletCoordinatorDidClickExit()
  }

  func walletViewControllerDidClickExchange(token: KNToken) {
    self.delegate?.walletCoordinatorDidClickExchange(token: token)
  }

  func walletViewControllerDidClickTransfer(token: KNToken) {
    self.delegate?.walletCoordinatorDidClickTransfer(token: token)
  }

  func walletViewControllerDidClickReceive(token: KNToken) {
    self.delegate?.walletCoordinatorDidClickReceive(token: token)
  }
}
