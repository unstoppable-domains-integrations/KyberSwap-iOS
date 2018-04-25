// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import SafariServices

protocol KNWalletCoordinatorDelegate: class {
  func walletCoordinatorDidClickExit()
  func walletCoordinatorDidClickExchange(token: KNToken)
  func walletCoordinatorDidClickTransfer(token: KNToken)
  func walletCoordinatorDidClickReceive(token: KNToken)
}

class KNWalletCoordinator: Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession

  weak var delegate: KNWalletCoordinatorDelegate?

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNWalletViewController = {
    let controller = KNWalletViewController(delegate: self)
    controller.loadViewIfNeeded()
    return controller
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.applyStyle()
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
  }
}

// Update from appcoordinator
extension KNWalletCoordinator {

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalances(otherTokensBalance)
    self.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH
    )
  }

  func appCoordinatorETHBalanceDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, ethBalance: Balance) {
    if let ethToken = KNJSONLoaderUtil.shared.tokens.first(where: { $0.isETH }) {
      self.rootViewController.coordinatorUpdateTokenBalances([ethToken.address: ethBalance])
    }
    self.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH
    )
  }

  func appCoordinatorExchangeRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    self.rootViewController.coordinatorUpdateBalanceInETHAndUSD(
      ethBalance: totalBalanceInETH,
      usdBalance: totalBalanceInUSD
    )
  }
}

extension KNWalletCoordinator: KNWalletViewControllerDelegate {
  func walletViewControllerDidExit() {
    self.stop()
    self.delegate?.walletCoordinatorDidClickExit()
  }

  func walletViewControllerDidClickTopView() {
    if let url = URL(string: KNEnvironment.default.etherScanIOURLString + "/address/" + self.session.wallet.address.description) {
      let controller = SFSafariViewController(url: url)
      self.navigationController.topViewController?.present(controller, animated: true, completion: nil)
    }
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
