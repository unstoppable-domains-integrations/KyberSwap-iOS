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
    self.rootViewController.coordinatorUpdateSelectedToken(token, isSource: !isReceived)
    self.rootViewController.tabBarController?.selectedIndex = 0
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.tokens = tokenObjects
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [Transaction]) {
    self.rootViewController.coordinatorDidUpdatePendingTransactions(transactions)
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
  func confirmTransactionDidCancel() {
    self.navigationController.topViewController?.dismiss(animated: false, completion: {
      self.confirmTransactionViewController = nil
    })
  }

  func confirmTransactionDidConfirm(type: KNTransactionType) {
    self.navigationController.topViewController?.dismiss(animated: false, completion: {
      self.confirmTransactionViewController = nil
      if case .exchange(let exchangeTransaction) = type {
        self.didConfirmSendExchangeTransaction(exchangeTransaction)
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
  func exchangeTabViewControllerFromTokenPressed(sender: KNExchangeTabViewController, from: TokenObject, to: TokenObject) {
    self.isSelectingSourceToken = true
    self.tokens = KNSupportedTokenStorage.shared.supportedTokens
    self.searchTokensViewController.updateListSupportedTokens(self.tokens)
    self.navigationController.pushViewController(
      self.searchTokensViewController,
      animated: true
    )
  }

  func exchangeTabViewControllerToTokenPressed(sender: KNExchangeTabViewController, from: TokenObject, to: TokenObject) {
    self.isSelectingSourceToken = false
    self.tokens = KNSupportedTokenStorage.shared.supportedTokens
    self.searchTokensViewController.updateListSupportedTokens(self.tokens)
    self.navigationController.pushViewController(
      self.searchTokensViewController,
      animated: true
    )
  }

  func exchangeTabViewControllerExchangeButtonPressed(sender: KNExchangeTabViewController, data: KNDraftExchangeTransaction) {
    let transactionType = KNTransactionType.exchange(data)
    self.confirmTransactionViewController = KNConfirmTransactionViewController(
      delegate: self,
      type: transactionType
    )
    self.confirmTransactionViewController.modalPresentationStyle = .overCurrentContext
    self.confirmTransactionViewController.modalTransitionStyle = .crossDissolve
    self.navigationController.topViewController?.present(
      self.confirmTransactionViewController,
      animated: true,
      completion: nil
    )
  }

  func exchangeTabViewControllerShouldUpdateEstimatedRate(from: TokenObject, to: TokenObject, amount: BigInt) {
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
        self?.rootViewController.coordinatorDidUpdateEstimateRate(
          from: from,
          to: to,
          amount: amount,
          rate: estRate,
          slippageRate: slippageRate
        )
    }
  }

  func exchangeTabViewControllerShouldUpdateEstimatedGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, gasPrice: BigInt) {
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

  func exchangeTabViewControllerDidPressedQRcode(sender: KNExchangeTabViewController) {
    self.qrcodeCoordinator?.start()
  }

  func exchangeTabViewControllerDidPressedGasPrice(gasPrice: BigInt, estGasLimit: BigInt) {
    let setGasPriceVC: KNSetGasPriceViewController = {
      let viewModel = KNSetGasPriceViewModel(gasPrice: gasPrice, estGasLimit: estGasLimit)
      let controller = KNSetGasPriceViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(setGasPriceVC, animated: true)
  }

  func exchangeTabViewControllerDidPressedSettings(sender: KNExchangeTabViewController) {
    //TODO: Open settings
  }

  func exchangeTabViewControllerDidPressedSendToken(sender: KNExchangeTabViewController) {
    self.sendTokenCoordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      from: self.session.tokenStorage.ethToken
    )
    self.sendTokenCoordinator?.start()
  }

  func exchangeTabViewControllerDidPressedAddWallet(sender: KNExchangeTabViewController) {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddWallet()
  }

  func exchangeTabViewControllerDidPressedWallet(_ wallet: KNWalletObject, sender: KNExchangeTabViewController) {
    self.delegate?.exchangeTokenCoordinatorDidSelectWallet(wallet)
  }
}

// MARK: Search token
extension KNExchangeTokenCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewControllerDidCancel() {
    self.navigationController.popViewController(animated: true)
  }

  func searchTokenViewControllerDidSelect(token: TokenObject) {
    self.navigationController.popViewController(animated: true) {
      self.rootViewController.coordinatorUpdateSelectedToken(
        token,
        isSource: self.isSelectingSourceToken
      )
    }
  }
}

// MARK: Set gas price
extension KNExchangeTokenCoordinator: KNSetGasPriceViewControllerDelegate {
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?) {
    self.navigationController.popViewController(animated: true) {
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
