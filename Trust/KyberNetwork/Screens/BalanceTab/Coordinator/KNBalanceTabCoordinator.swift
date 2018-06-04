// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNBalanceTabCoordinatorDelegate: class {
  func balanceTabCoordinatorShouldOpenExchange(for tokenObject: TokenObject)
  func balanceTabCoordinatorShouldOpenSend(for tokenObject: TokenObject)
  func balanceTabCoordinatorDidSelect(walletObject: KNWalletObject)
}

class KNBalanceTabCoordinator: Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession
  var coordinators: [Coordinator] = []

  fileprivate var balances: [String: Balance] = [:]

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

  fileprivate var qrcodeCoordinator: KNWalletQRCodeCoordinator? {
    guard let walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.session.wallet.address.description) else { return nil }
    let qrcodeCoordinator = KNWalletQRCodeCoordinator(
      navigationController: self.navigationController,
      walletObject: walletObject
    )
    return qrcodeCoordinator
  }

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.applyStyle()
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
    let viewModel: KNBalanceTabViewModel = {
      let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
      let address: String = session.wallet.address.description
      let walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
      let viewModel = KNBalanceTabViewModel(wallet: walletObject)
      _ = viewModel.updateTokenObjects(tokenObjects)
      return viewModel
    }()
    self.rootViewController.coordinatorUpdateSessionWithNewViewModel(viewModel)
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalances(otherTokensBalance)
    self.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH
    )
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }
  func appCoordinatorETHBalanceDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, ethBalance: Balance) {
    if let ethToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.isETH }) {
      self.rootViewController.coordinatorUpdateTokenBalances([ethToken.contract: ethBalance])
      self.balances[ethToken.contract] = ethBalance
    }
    self.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH
    )
    self.sendTokenCoordinator?.coordinatorETHBalanceDidUpdate(ethBalance: ethBalance)
  }

  func appCoordinatorExchangeRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    self.rootViewController.coordinatorUpdateBalanceInETHAndUSD(
      ethBalance: totalBalanceInETH,
      usdBalance: totalBalanceInUSD
    )
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  func appCoordinatorCoinTickerDidUpdate() {
    self.rootViewController.coordinatorCoinTickerDidUpdate()
  }

  func appCoordinatorSupportedTokensDidUpdate(tokenObjects: [TokenObject]) {
    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(self.session.tokenStorage.tokens)
  }
}

extension KNBalanceTabCoordinator: KNBalanceTabViewControllerDelegate {
  func balanceTabDidSelectQRCodeButton(in controller: KNBalanceTabViewController) {
    self.qrcodeCoordinator?.start()
  }

//  func balanceTabDidSelectAddTokenButton(in controller: KNBalanceTabViewController) {
//    // TODO: Implement it
//    let controller = NewTokenViewController(token: nil)
//    controller.delegate = self
//    let navController = UINavigationController(rootViewController: controller)
//    navController.applyStyle()
//    self.navigationController.topViewController?.present(navController, animated: true, completion: nil)
//  }

  func balanceTabDidSelectToken(_ tokenObject: TokenObject, in controller: KNBalanceTabViewController) {
    // TODO: Temp open send token view
    self.sendTokenCoordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      from: tokenObject
    )
    self.sendTokenCoordinator?.delegate = self
    self.sendTokenCoordinator?.start()
  }

  func balanceTabDidSelectWalletObject(_ walletObject: KNWalletObject, in controller: KNBalanceTabViewController) {
    self.delegate?.balanceTabCoordinatorDidSelect(walletObject: walletObject)
  }

  func balanceTabDidSelectManageWallet(in controller: KNBalanceTabViewController) {
    //TODO: Implement it
  }

  func balanceTabDidSelectSettings(in controller: KNBalanceTabViewController) {
    //TODO: Implement it
  }
}

// MARK: New Token Delegate
extension KNBalanceTabCoordinator: NewTokenViewControllerDelegate {
  func didAddToken(token: ERC20Token, in viewController: NewTokenViewController) {
    self.session.tokenStorage.addCustom(token: token)
    self.navigationController.topViewController?.dismiss(animated: true, completion: {
      KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
    })
  }

  func didCancel(in viewController: NewTokenViewController) {
    self.navigationController.topViewController?.dismiss(animated: true, completion: nil)
  }
}

// MARK: Send Token Coordinator Delegate
extension KNBalanceTabCoordinator: KNSendTokenViewCoordinatorDelegate {
  func sendTokenCoordinatorDidPressBack() {
    self.navigationController.popViewController(animated: true)
  }
}
