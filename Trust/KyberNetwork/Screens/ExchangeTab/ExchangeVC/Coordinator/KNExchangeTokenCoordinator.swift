// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore

class KNExchangeTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  fileprivate(set) var session: KNSession
  let tokens: [KNToken] = KNJSONLoaderUtil.shared.tokens
  var isSelectingSourceToken: Bool = true

  weak var delegate: KNSessionDelegate?

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNExchangeTokenViewController = {
    let controller = KNExchangeTokenViewController(delegate: self)
    controller.loadViewIfNeeded()
    return controller
  }()

  lazy var selectTokenViewController: KNSelectTokenViewController = {
    let controller = KNSelectTokenViewController(delegate: self, availableTokens: self.tokens)
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
    self.navigationController.applyStyle()
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorDidUpdateBalance(usd: totalBalanceInUSD, eth: totalBalanceInETH)
    self.rootViewController.coordinatorDidUpdateOtherTokenBalanceDidUpdate(balances: otherTokensBalance)
    self.selectTokenViewController.updateTokenBalances(otherTokensBalance)
  }

  func appCoordinatorETHBalanceDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, ethBalance: Balance) {
    self.rootViewController.coordinatorDidUpdateBalance(usd: totalBalanceInUSD, eth: totalBalanceInETH)
    self.rootViewController.coordinatorDidUpdateEthBalanceDidUpdate(balance: ethBalance)
    self.selectTokenViewController.updateETHBalance(ethBalance)
  }

  func appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    self.rootViewController.coordinatorDidUpdateBalance(usd: totalBalanceInUSD, eth: totalBalanceInETH)
  }

  func appCoordinatorShouldOpenExchangeForToken(_ token: KNToken, isReceived: Bool = false) {
    self.rootViewController.coordinatorDidUpdateSelectedToken(token, isSource: !isReceived)
    self.rootViewController.tabBarController?.selectedIndex = 0
  }

  fileprivate func didConfirmSendExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    self.navigationController.topViewController?.displayLoading()
    self.session.externalProvider.getAllowance(token: exchangeTransaction.from) { [weak self] getAllowanceResult in
      guard let `self` = self else { return }
      switch getAllowanceResult {
      case .success(let res):
        if res {
          self.sendExchangeTransaction(exchangeTransaction)
        } else {
          self.navigationController.topViewController?.hideLoading()
          self.showAlertRequestApprovalForExchange(exchangeTransaction)
        }
      case .failure(let error):
        self.navigationController.topViewController?.hideLoading()
        self.rootViewController.displayError(error: error)
      }
    }
  }

  fileprivate func sendExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    // Lock all data for exchange transaction first
    KNTransactionCoordinator.requestDataPrepareForExchangeTransaction(
      exchangeTransaction,
      provider: self.session.externalProvider) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let tx):
        guard let exchange = tx else {
          // Return nil when balance is too low compared to the amoun
          // Show error balance insufficient
          self.navigationController.topViewController?.hideLoading()
          self.navigationController.topViewController?.showInsufficientBalanceAlert()
          return
        }
        self.session.externalProvider.exchange(exchange: exchange) { [weak self] result in
          guard let `self` = self else { return }
          self.navigationController.topViewController?.hideLoading()
          self.rootViewController.coordinatorExchangeTokenDidReturn(result: result)
          if case .success(let txHash) = result {
            let transaction = exchange.toTransaction(
              hash: txHash,
              fromAddr: self.session.wallet.address,
              toAddr: self.session.externalProvider.networkAddress,
              nounce: self.session.externalProvider.minTxCount
            )
            self.session.addNewPendingTransaction(transaction)
          }
        }
      case .failure(let error):
        self.navigationController.topViewController?.hideLoading()
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }

  fileprivate func sendApproveForExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    self.navigationController.topViewController?.displayLoading()
    self.session.externalProvider.sendApproveERC20Token(exchangeTransaction: exchangeTransaction) { [weak self] result in
      switch result {
      case .success:
        self?.sendExchangeTransaction(exchangeTransaction)
      case .failure(let error):
        self?.navigationController.topViewController?.hideLoading()
        self?.navigationController.topViewController?.displayError(error: error)
      }
    }
  }

  fileprivate func showAlertRequestApprovalForExchange(_ exchangeTransaction: KNDraftExchangeTransaction) {
    let alertController = UIAlertController(title: "", message: "We need your approval to exchange \(exchangeTransaction.from.symbol)", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Approve", style: .default, handler: { [weak self] _ in
      self?.sendApproveForExchangeTransaction(exchangeTransaction)
    }))
    self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
  }
}

extension KNExchangeTokenCoordinator: KNExchangeTokenViewControllerDelegate {
  func exchangeTokenAmountDidChange(source: KNToken, dest: KNToken, amount: BigInt) {
    self.session.externalProvider.getExpectedRate(
      from: source,
      to: dest,
      amount: amount) { [weak self] (result) in
        if case .success(let data) = result {
          self?.rootViewController.coordinatorDidUpdateEstimateRate(
            source: source,
            dest: dest,
            amount: amount,
            expectedRate: data.0,
            slippageRate: data.1
          )
          if self?.confirmTransactionViewController != nil {
            self?.confirmTransactionViewController.updateExpectedRateData(
              source: source,
              dest: dest,
              amount: amount,
              expectedRate: data.0
            )
          }
        }
    }
  }

  func exchangeTokenShouldUpdateEstimateGasUsed(exchangeTransaction: KNDraftExchangeTransaction) {
    self.session.externalProvider.getEstimateGasLimit(for: exchangeTransaction) { [weak self] result in
      if case .success(let estimate) = result {
        self?.rootViewController.coordinatorDidUpdateEstimateGasUsed(
          source: exchangeTransaction.from,
          dest: exchangeTransaction.to,
          amount: exchangeTransaction.amount,
          estimate: estimate
        )
      }
    }
  }

  func exchangeTokenDidClickExchange(exchangeTransaction: KNDraftExchangeTransaction) {
    let transactionType = KNTransactionType.exchange(exchangeTransaction)
    self.confirmTransactionViewController = KNConfirmTransactionViewController(
      delegate: self,
      type: transactionType
    )
    self.confirmTransactionViewController.modalPresentationStyle = .overCurrentContext
    self.navigationController.topViewController?.present(self.confirmTransactionViewController, animated: false, completion: nil)
  }

  func exchangeTokenUserDidClickSelectTokenButton(source: KNToken, dest: KNToken, isSource: Bool) {
    self.isSelectingSourceToken = isSource
    self.navigationController.pushViewController(self.selectTokenViewController, animated: true)
  }

  func exchangeTokenUserDidClickPendingTransactions() {
    self.addCoordinator(self.pendingTransactionListCoordinator)
    self.pendingTransactionListCoordinator.start()
  }

  func exchangeTokenUserDidClickExit() {
    self.stop()
    self.delegate?.userDidClickExitSession()
  }
}

extension KNExchangeTokenCoordinator: KNSelectTokenViewControllerDelegate {
  func selectTokenViewUserDidSelect(_ token: KNToken) {
    self.navigationController.popViewController(animated: true) {
      self.rootViewController.coordinatorDidUpdateSelectedToken(token, isSource: self.isSelectingSourceToken)
    }
  }
}

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
