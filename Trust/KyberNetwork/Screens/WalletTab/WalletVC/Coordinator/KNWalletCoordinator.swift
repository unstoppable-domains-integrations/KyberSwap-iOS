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

  fileprivate var tokens: [TokenObject] {
    return self.session.tokenStorage.tokens
  }

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
    self.rootViewController.coordinatorUpdateTokenObjects(self.tokens)
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() { }
}

// Update from appcoordinator
extension KNWalletCoordinator {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    self.navigationController.popToRootViewController(animated: false)
    self.rootViewController.coordinatorUpdateTokenObjects(self.tokens)
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

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
  }
}

extension KNWalletCoordinator: KNWalletViewControllerDelegate {
  func walletViewController(_ controller: KNWalletViewController, didExit sender: Any) {
    self.stop()
    self.delegate?.walletCoordinatorDidClickExit()
  }

  func walletViewController(_ controller: KNWalletViewController, didClickWallet sender: Any) {
    if let url = URL(string: KNEnvironment.default.etherScanIOURLString + "/address/" + self.session.wallet.address.description) {
      let controller = SFSafariViewController(url: url)
      self.navigationController.topViewController?.present(controller, animated: true, completion: nil)
    }
  }

  func walletViewController(_ controller: KNWalletViewController, didClickExchange token: KNToken) {
    self.delegate?.walletCoordinatorDidClickExchange(token: token)
  }

  func walletViewController(_ controller: KNWalletViewController, didClickTransfer token: KNToken) {
    self.delegate?.walletCoordinatorDidClickTransfer(token: token)
  }

  func walletViewController(_ controller: KNWalletViewController, didClickReceive token: KNToken) {
    self.delegate?.walletCoordinatorDidClickReceive(token: token)
  }

  func walletViewController(_ controller: KNWalletViewController, didClickAddTokenManually sender: Any) {
    let viewController = NewTokenViewController(token: .none)
    viewController.delegate = self
    self.navigationController.pushViewController(viewController, animated: true)
  }
}

extension KNWalletCoordinator: NewTokenViewControllerDelegate {
  func didCancel(in viewController: NewTokenViewController) {
    self.navigationController.popViewController(animated: true)
  }

  func didAddToken(token: ERC20Token, in viewController: NewTokenViewController) {
    self.session.tokenStorage.addCustom(token: token)
    KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
    self.navigationController.popViewController(animated: true)
  }
}
