// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNBalanceTabCoordinatorDelegate: class {
  func balanceTabCoordinatorShouldOpenExchange(for tokenObject: TokenObject)
  func balanceTabCoordinatorShouldOpenSend(for tokenObject: TokenObject)
}

class KNBalanceTabCoordinator: Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession
  var coordinators: [Coordinator] = []

  weak var delegate: KNBalanceTabCoordinatorDelegate?

  lazy var rootViewController: KNBalanceTabViewController = {
    let address: String = self.session.wallet.address.description
    let wallet: KNWalletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    let viewModel: KNBalanceTabViewModel = KNBalanceTabViewModel(wallet: wallet)
    let controller: KNBalanceTabViewController = KNBalanceTabViewController(with: viewModel)
    controller.delegate = self
    controller.loadViewIfNeeded()
    return controller
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  func start() {
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() { }
}

// Update from appcoordinator
extension KNBalanceTabCoordinator {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    self.navigationController.popToRootViewController(animated: false)
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
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

  func appCoordinatorCoinTickerDidUpdate() {
    self.rootViewController.coordinatorCoinTickerDidUpdate()
  }
}

extension KNBalanceTabCoordinator: KNBalanceTabViewControllerDelegate {
  func balanceTabDidSelectQRCodeButton(in controller: KNBalanceTabViewController) {
  }

  func balanceTabDidSelectAddTokenButton(in controller: KNBalanceTabViewController) {
  }

  func balanceTabDidSelectWalletListButton(in controller: KNBalanceTabViewController) {
  }

  func balanceTabDidSelectSend(for tokenObject: TokenObject, in controller: KNBalanceTabViewController) {
    self.delegate?.balanceTabCoordinatorShouldOpenSend(for: tokenObject)
  }

  func balanceTabDidSelectExchange(for tokenObject: TokenObject, in controller: KNBalanceTabViewController) {
    self.delegate?.balanceTabCoordinatorShouldOpenExchange(for: tokenObject)
  }
}
