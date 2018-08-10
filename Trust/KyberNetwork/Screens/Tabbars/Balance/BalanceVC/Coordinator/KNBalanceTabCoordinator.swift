// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNBalanceTabCoordinatorDelegate: class {
  func balanceTabCoordinatorShouldOpenExchange(for tokenObject: TokenObject, isReceived: Bool)
  func balanceTabCoordinatorDidSelect(walletObject: KNWalletObject)
  func balancetabCoordinatorDidSelectAddWallet()
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

  lazy var newRootViewController: KWalletBalanceViewController = {
    let address: String = self.session.wallet.address.description
    let wallet: KNWalletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    let viewModel: KWalletBalanceViewModel = KWalletBalanceViewModel(wallet: wallet)
    let controller: KWalletBalanceViewController = KWalletBalanceViewController(viewModel: viewModel)
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

  lazy var historyCoordinator: KNHistoryCoordinator = {
    let coordinator = KNHistoryCoordinator(
      navigationController: self.navigationController,
      session: self.session)
    return coordinator
  }()

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
  fileprivate var tokenChartCoordinator: KNTokenChartCoordinator?
  fileprivate var marketCoordinator: KMarketViewCoordinator?

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
//    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    self.newRootViewController.coordinatorUpdateTokenObjects(tokenObjects)
//    self.navigationController.viewControllers = [self.rootViewController]
    self.navigationController.viewControllers = [self.newRootViewController]
  }

  func stop() { }
}

// Update from appcoordinator
extension KNBalanceTabCoordinator {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    if resetRoot {
      self.navigationController.popToRootViewController(animated: false)
    }
//    let viewModel: KNBalanceTabViewModel = {
//      let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
//      let address: String = session.wallet.address.description
//      let walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
//      let viewModel = KNBalanceTabViewModel(wallet: walletObject)
//      _ = viewModel.updateTokenObjects(tokenObjects)
//      return viewModel
//    }()

    let viewModel: KWalletBalanceViewModel = {
      let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
      let address: String = session.wallet.address.description
      let walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
      let viewModel = KWalletBalanceViewModel(wallet: walletObject)
      _ = viewModel.updateTokenObjects(tokenObjects)
      return viewModel
    }()
//    self.rootViewController.coordinatorUpdateSessionWithNewViewModel(viewModel)
    self.newRootViewController.coordinatorUpdateSessionWithNewViewModel(viewModel)
    let pendingObjects = self.session.transactionStorage.kyberPendingTransactions
//    self.rootViewController.coordinatorUpdatePendingTransactions(pendingObjects)
    self.newRootViewController.coordinatorUpdatePendingTransactions(pendingObjects)
    self.historyCoordinator.appCoordinatorPendingTransactionDidUpdate(pendingObjects)
    self.marketCoordinator?.coordinatorDidUpdateNewSession()
  }

  func appCoordinatorDidUpdateWalletObjects() {
//    self.rootViewController.coordinatorUpdateWalletObjects()
    self.newRootViewController.coordinatorUpdateWalletObjects()
    self.historyCoordinator.appCoordinatorDidUpdateWalletObjects()
  }

  func appCoordinatorTokenBalancesDidUpdate(
    totalBalanceInUSD: BigInt,
    totalBalanceInETH: BigInt,
    otherTokensBalance: [String: Balance]
    ) {
//    self.rootViewController.coordinatorUpdateTokenBalances(otherTokensBalance)
    self.newRootViewController.coordinatorUpdateTokenBalances(otherTokensBalance)
    self.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH
    )
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.tokenChartCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }

  func appCoordinatorETHBalanceDidUpdate(
    totalBalanceInUSD: BigInt,
    totalBalanceInETH: BigInt,
    ethBalance: Balance
    ) {
    if let ethToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.isETH }) {
//      self.rootViewController.coordinatorUpdateTokenBalances([ethToken.contract: ethBalance])
      self.newRootViewController.coordinatorUpdateTokenBalances([ethToken.contract: ethBalance])
      self.balances[ethToken.contract] = ethBalance
    }
    self.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH
    )
    self.tokenChartCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
    self.sendTokenCoordinator?.coordinatorETHBalanceDidUpdate(ethBalance: ethBalance)
  }

  func appCoordinatorExchangeRateDidUpdate(
    totalBalanceInUSD: BigInt,
    totalBalanceInETH: BigInt
    ) {
    self.tokenChartCoordinator?.coordinatorExchangeRateDidUpdate()
//    self.rootViewController.coordinatorUpdateBalanceInETHAndUSD(
//      ethBalance: totalBalanceInETH,
//      usdBalance: totalBalanceInUSD
//    )
    self.newRootViewController.coordinatorUpdateBalanceInETHAndUSD(
      ethBalance: totalBalanceInETH,
      usdBalance: totalBalanceInUSD
    )
    self.marketCoordinator?.coordinatorUpdateTrackerRate()
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
//    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    self.newRootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    self.tokenChartCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
    self.marketCoordinator?.coordinatorDidUpdateTokenObjects(tokenObjects)
  }

  func appCoordinatorSupportedTokensDidUpdate(tokenObjects: [TokenObject]) {
//    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    let tokens = self.session.tokenStorage.tokens
    self.newRootViewController.coordinatorUpdateTokenObjects(tokens)
    self.tokenChartCoordinator?.coordinatorTokenObjectListDidUpdate(tokens)
    self.marketCoordinator?.coordinatorDidUpdateTokenObjects(tokens)
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [KNTransaction]) {
//    self.rootViewController.coordinatorUpdatePendingTransactions(transactions)
    self.newRootViewController.coordinatorUpdatePendingTransactions(transactions)
    self.historyCoordinator.appCoordinatorPendingTransactionDidUpdate(transactions)
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.tokenChartCoordinator?.coordinatorGasPriceCachedDidUpdate()
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator.appCoordinatorTokensTransactionsDidUpdate()
  }
}

// MARK: New Design K Wallet Balance delegation
extension KNBalanceTabCoordinator: KWalletBalanceViewControllerDelegate {
  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run event: KWalletBalanceViewEvent) {
    switch event {
    case .openQRCode:
      self.qrcodeCoordinator?.start()
    case .selectToken(let token):
      self.openTokenChartView(for: token)
    case .openMarketView:
      self.openMarketView()
    }
  }

  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run menuEvent: KNBalanceTabHamburgerMenuViewEvent) {
    switch menuEvent {
    case .select(let wallet):
      self.hamburgerMenu(select: wallet)
    case .selectAddWallet:
      self.hamburgerMenuSelectAddWallet()
    case .selectSendToken:
      self.openSendTokenView()
    case .selectAllTransactions:
      self.openHistoryTransactionView()
    }
  }
}

// TODO: Remove when done with new design
extension KNBalanceTabCoordinator: KNBalanceTabViewControllerDelegate {

  func balanceTabViewController(_ controller: KNBalanceTabViewController, run event: KNBalanceTabViewEvent) {
    switch event {
    case .selectQRCode:
      self.qrcodeCoordinator?.start()
    case .select(let token):
      self.openTokenChartView(for: token)
    }
  }

  func balanceTabViewController(_ controller: KNBalanceTabViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    switch event {
    case .select(let wallet):
      self.hamburgerMenu(select: wallet)
    case .selectAddWallet:
      self.hamburgerMenuSelectAddWallet()
    case .selectSendToken:
      self.openSendTokenView()
    case .selectAllTransactions:
      self.openHistoryTransactionView()
    }
  }

  fileprivate func openTokenChartView(for tokenObject: TokenObject) {
    self.tokenChartCoordinator = KNTokenChartCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      token: tokenObject
    )
    self.tokenChartCoordinator?.delegate = self
    self.tokenChartCoordinator?.start()
  }

  fileprivate func openMarketView() {
    self.marketCoordinator = KMarketViewCoordinator(
      navigationController: self.navigationController,
      currencyType: KNAppTracker.getCurrencyType()
    )
    self.marketCoordinator?.delegate = self
    self.marketCoordinator?.start()
    self.marketCoordinator?.coordinatorDidUpdateTokenObjects(self.session.tokenStorage.tokens)
  }

  func hamburgerMenu(select walletObject: KNWalletObject) {
    self.delegate?.balanceTabCoordinatorDidSelect(walletObject: walletObject)
  }

  func hamburgerMenuSelectAddWallet() {
    self.delegate?.balancetabCoordinatorDidSelectAddWallet()
  }

  func openSendTokenView() {
    self.sendTokenCoordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      from: self.session.tokenStorage.ethToken
    )
    self.sendTokenCoordinator?.start()
  }

  func openHistoryTransactionView() {
    self.historyCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.historyCoordinator.start()
  }
}

// MARK: Market Delegation
extension KNBalanceTabCoordinator: KMarketViewCoordinatorDelegate {
  func kMarketViewCoordinator(_ coordinator: KMarketViewCoordinator, run event: KMarketsViewEvent) {
    switch event {
    case .close: self.marketCoordinator?.stop { self.marketCoordinator = nil }
    case .selectToken(let token):
      self.openTokenChartView(for: token)
    }
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

// MARK: Token Chart Coordinator Delegate
extension KNBalanceTabCoordinator: KNTokenChartCoordinatorDelegate {
  func tokenChartCoordinator(sell token: TokenObject) {
    self.delegate?.balanceTabCoordinatorShouldOpenExchange(for: token, isReceived: false)
  }

  func tokenChartCoordinator(buy token: TokenObject) {
    self.delegate?.balanceTabCoordinatorShouldOpenExchange(for: token, isReceived: true)
  }
}
