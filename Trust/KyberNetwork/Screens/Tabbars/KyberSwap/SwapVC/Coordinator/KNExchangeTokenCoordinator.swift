// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore

protocol KNExchangeTokenCoordinatorDelegate: class {
  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: KNWalletObject)
  func exchangeTokenCoordinatorDidSelectAddWallet()
}

class KNExchangeTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  fileprivate(set) var session: KNSession
  var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  var isSelectingSourceToken: Bool = true

  var coordinators: [Coordinator] = []

  fileprivate var balances: [String: Balance] = [:]
  weak var delegate: KNExchangeTokenCoordinatorDelegate?

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
  fileprivate var setGasPriceVC: KNSetGasPriceViewController?

  lazy var rootViewController: KNExchangeTabViewController = {
    let viewModel = KNExchangeTabViewModel(
      wallet: self.session.wallet,
      from: KNSupportedTokenStorage.shared.ethToken,
      to: KNSupportedTokenStorage.shared.kncToken,
      supportedTokens: tokens
    )
    let controller = KNExchangeTabViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
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

  lazy var searchTokensViewController: KNSearchTokenViewController = {
    let viewModel = KNSearchTokenViewModel(supportedTokens: self.tokens)
    let controller = KNSearchTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var pendingTransactionListCoordinator: KNPendingTransactionListCoordinator = {
    let coordinator = KNPendingTransactionListCoordinator(
      navigationController: self.navigationController,
      storage: self.session.transactionStorage
    )
    coordinator.delegate = self
    return coordinator
  }()

  fileprivate var confirmTransactionViewController: KNConfirmTransactionViewController!

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
  }
}

// MARK: Update from app coordinator
extension KNExchangeTokenCoordinator {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    let pendingTrans = self.session.transactionStorage.pendingObjects
    self.rootViewController.coordinatorDidUpdatePendingTransactions(pendingTrans)
    self.historyCoordinator.appCoordinatorPendingTransactionDidUpdate(pendingTrans)
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalance(otherTokensBalance)
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }

  func appCoordinatorETHBalanceDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, ethBalance: Balance) {
    if let eth = self.tokens.first(where: { $0.isETH }) {
      self.balances[eth.contract] = ethBalance
      self.rootViewController.coordinatorUpdateTokenBalance([eth.contract: ethBalance])
    }
    self.sendTokenCoordinator?.coordinatorETHBalanceDidUpdate(ethBalance: ethBalance)
  }

  func appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    // No need
  }

  func appCoordinatorShouldOpenExchangeForToken(_ token: TokenObject, isReceived: Bool = false) {
    self.navigationController.popToRootViewController(animated: true)
    self.rootViewController.coordinatorUpdateSelectedToken(token, isSource: !isReceived)
    self.rootViewController.tabBarController?.selectedIndex = 1
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.tokens = tokenObjects
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [Transaction]) {
    self.rootViewController.coordinatorDidUpdatePendingTransactions(transactions)
    self.historyCoordinator.appCoordinatorPendingTransactionDidUpdate(transactions)
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.rootViewController.coordinatorUpdateGasPriceCached()
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator.appCoordinatorTokensTransactionsDidUpdate()
  }
}

// MARK: Network requests
extension KNExchangeTokenCoordinator {
  fileprivate func didConfirmSendExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    self.rootViewController.coordinatorExchangeTokenUserDidConfirmTransaction()
    KNNotificationUtil.postNotification(for: kTransactionDidUpdateNotificationKey)
    self.session.externalProvider.getAllowance(token: exchangeTransaction.from) { [weak self] getAllowanceResult in
      guard let `self` = self else { return }
      switch getAllowanceResult {
      case .success(let res):
        if res {
          self.sendExchangeTransaction(exchangeTransaction)
        } else {
          self.sendApproveForExchangeTransaction(exchangeTransaction)
        }
      case .failure(let error):
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
      }
    }
  }

  fileprivate func sendExchangeTransaction(_ exchage: KNDraftExchangeTransaction) {
    // Lock all data for exchange transaction first
    self.session.externalProvider.exchange(exchange: exchage) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let txHash):
        let transaction = exchage.toTransaction(
          hash: txHash,
          fromAddr: self.session.wallet.address,
          toAddr: self.session.externalProvider.networkAddress,
          nounce: self.session.externalProvider.minTxCount
        )
        self.session.addNewPendingTransaction(transaction)
      case .failure(let error):
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
      }
    }
  }

  fileprivate func sendApproveForExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    self.session.externalProvider.sendApproveERC20Token(exchangeTransaction: exchangeTransaction) { [weak self] result in
      switch result {
      case .success:
        self?.sendExchangeTransaction(exchangeTransaction)
      case .failure(let error):
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
      }
    }
  }
}

// MARK: Confirm transaction
extension KNExchangeTokenCoordinator: KNConfirmTransactionViewControllerDelegate {
  func confirmTransactionViewController(_ controller: KNConfirmTransactionViewController, run event: KNConfirmTransactionViewEvent) {
    self.navigationController.dismiss(animated: true, completion: {
      switch event {
      case .cancel:
        self.confirmTransactionViewController = nil
      case .confirm(let type):
        self.confirmTransactionViewController = nil
        if case .exchange(let exchangeTransaction) = type {
          self.didConfirmSendExchangeTransaction(exchangeTransaction)
        }
      }
    })
  }
}

// MARK: Pending transaction list
extension KNExchangeTokenCoordinator: KNPendingTransactionListCoordinatorDelegate {
  func pendingTransactionListDidSelectTransferNow() {
    self.rootViewController.tabBarController?.selectedIndex = 1
  }

  func pendingTransactionListDidSelectExchangeNow() {
    self.rootViewController.tabBarController?.selectedIndex = 0
  }

  func pendingTransactionListDidSelectTransaction(_ transaction: Transaction) {
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: transaction.id,
      userInfo: nil
    )
  }
}

// MARK: Exchange tab (root view controller)
extension KNExchangeTokenCoordinator: KNExchangeTabViewControllerDelegate {
  func exchangeTabViewController(_ controller: KNExchangeTabViewController, run event: KNExchangeTabViewEvent) {
    switch event {
    case .searchToken(let from, let to, let isSource):
      self.openSearchToken(from: from, to: to, isSource: isSource)
    case .estimateRate(let from, let to, let amount):
      self.updateEstimatedRate(from: from, to: to, amount: amount)
    case .estimateGas(let from, let to, let amount, let gasPrice):
      self.updateEstimatedGasLimit(from: from, to: to, amount: amount, gasPrice: gasPrice)
    case .showQRCode:
      self.showWalletQRCode()
    case .setGasPrice(let gasPrice, let gasLimit):
      self.openSetGasPrice(gasPrice: gasPrice, estGasLimit: gasLimit)
    case .exchange(let data):
      self.exchangeButtonPressed(data: data)
    }
  }

  func exchangeTabViewController(_ controller: KNExchangeTabViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    switch event {
    case .selectSettings:
      self.openSettingsView()
    case .selectSendToken:
      self.openSendTokenView()
    case .selectAddWallet:
      self.openAddWalletView()
    case .select(let wallet):
      self.updateCurrentWallet(wallet)
    case .selectAllTransactions:
      self.historyCoordinator.appCoordinatorDidUpdateNewSession(self.session)
      self.historyCoordinator.start()
    }
  }

  fileprivate func openSearchToken(from: TokenObject, to: TokenObject, isSource: Bool) {
    self.isSelectingSourceToken = isSource
    self.tokens = KNSupportedTokenStorage.shared.supportedTokens
    self.searchTokensViewController.updateListSupportedTokens(self.tokens)
    self.navigationController.present(self.searchTokensViewController, animated: true, completion: nil)
  }

  fileprivate func exchangeButtonPressed(data: KNDraftExchangeTransaction) {
    self.confirmTransactionViewController = {
      let transactionType = KNTransactionType.exchange(data)
      let viewModel = KNConfirmTransactionViewModel(type: transactionType)
      let controller = KNConfirmTransactionViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.confirmTransactionViewController.modalPresentationStyle = .overFullScreen
    self.confirmTransactionViewController.modalTransitionStyle = .crossDissolve
    self.navigationController.present(
      self.confirmTransactionViewController,
      animated: true,
      completion: nil
    )
  }

  fileprivate func updateEstimatedRate(from: TokenObject, to: TokenObject, amount: BigInt) {
    self.session.externalProvider.getExpectedRate(
      from: from,
      to: to,
      amount: amount) { [weak self] (result) in
        var estRate: BigInt = BigInt(0)
        var slippageRate: BigInt = BigInt(0)
        if case .success(let data) = result {
          estRate = data.0
          slippageRate = data.1
        }
        // fallback to rate from CMC
        if estRate.isZero, let cmcRate = KNRateCoordinator.shared.getRate(from: from, to: to) {
          estRate = cmcRate.rate
          slippageRate = cmcRate.minRate
        }
        estRate /= BigInt(10).power(18 - to.decimals)
        slippageRate /= BigInt(10).power(18 - to.decimals)
        self?.rootViewController.coordinatorDidUpdateEstimateRate(
          from: from,
          to: to,
          amount: amount,
          rate: estRate,
          slippageRate: slippageRate
        )
    }
  }

  func updateEstimatedGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, gasPrice: BigInt) {
    let exchangeTx = KNDraftExchangeTransaction(
      from: from,
      to: to,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: BigInt(0),
      minRate: .none,
      gasPrice: gasPrice,
      gasLimit: .none
    )
    self.session.externalProvider.getEstimateGasLimit(for: exchangeTx) { [weak self] result in
      if case .success(let estimate) = result {
        self?.rootViewController.coordinatorDidUpdateEstimateGasUsed(
          from: from,
          to: to,
          amount: amount,
          gasLimit: estimate
        )
      }
    }
  }

  fileprivate func showWalletQRCode() {
    self.qrcodeCoordinator?.start()
  }

  fileprivate func openSetGasPrice(gasPrice: BigInt, estGasLimit: BigInt) {
    let setGasPriceVC: KNSetGasPriceViewController = {
      let viewModel = KNSetGasPriceViewModel(gasPrice: gasPrice, estGasLimit: estGasLimit)
      let controller = KNSetGasPriceViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.setGasPriceVC = setGasPriceVC
    self.navigationController.pushViewController(setGasPriceVC, animated: true)
  }

  fileprivate func openSettingsView() {
    //TODO: Open settings
  }

  fileprivate func openSendTokenView() {
    self.sendTokenCoordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      from: self.session.tokenStorage.ethToken
    )
    self.sendTokenCoordinator?.start()
  }

  fileprivate func openAddWalletView() {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddWallet()
  }

  fileprivate func updateCurrentWallet(_ wallet: KNWalletObject) {
    self.delegate?.exchangeTokenCoordinatorDidSelectWallet(wallet)
  }
}

// MARK: Search token
extension KNExchangeTokenCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    self.searchTokensViewController.dismiss(animated: true) {
      if case .select(let token) = event {
        self.rootViewController.coordinatorUpdateSelectedToken(
          token,
          isSource: self.isSelectingSourceToken
        )
      }
    }
  }
}

// MARK: Set gas price
extension KNExchangeTokenCoordinator: KNSetGasPriceViewControllerDelegate {
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?) {
    self.navigationController.popViewController(animated: true) {
      self.setGasPriceVC = nil
      self.rootViewController.coordinatorExchangeTokenDidUpdateGasPrice(gasPrice)
    }
  }
}

// MARK: Add new wallet delegate
extension KNExchangeTokenCoordinator: KNAddNewWalletCoordinatorDelegate {
  func addNewWalletCoordinator(add wallet: Wallet) {
    let address = wallet.address.description
    let walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    self.delegate?.exchangeTokenCoordinatorDidSelectWallet(walletObject)
  }
}

// MARK: History transaction
