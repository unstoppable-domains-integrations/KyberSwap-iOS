// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore

class KNExchangeTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession
  let balanceCoordinator: KNBalanceCoordinator
  let tokens: [KNToken] = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
  var isSelectingSourceToken: Bool = true

  weak var delegate: KNSessionDelegate?

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNExchangeTokenViewController = {
    let controller = KNExchangeTokenViewController(delegate: self)
    return controller
  }()

  lazy var selectTokenViewController: KNSelectTokenViewController = {
    let controller = KNSelectTokenViewController(delegate: self, availableTokens: self.tokens)
    return controller
  }()

  lazy var pendingTransactionListCoordinator: KNPendingTransactionListCoordinator = {
    let coordinator = KNPendingTransactionListCoordinator(
      navigationController: self.navigationController,
      storage: self.session.storage
    )
    coordinator.delegate = self
    return coordinator
  }()

  fileprivate var confirmTransactionViewController: KNConfirmTransactionViewController!

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
    self.addObserveNotifications()
  }

  func stop() {
    self.removeObserveNotifications()
  }

  fileprivate func addObserveNotifications() {
    let ethBalanceName = Notification.Name(kETHBalanceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.ethBalanceDidUpdateNotification(_:)),
      name: ethBalanceName,
      object: nil
    )
    let tokenBalanceName = Notification.Name(kOtherBalanceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenBalancesDidUpdateNotification(_:)),
      name: tokenBalanceName,
      object: nil
    )
    let rateUSDName = Notification.Name(kExchangeUSDRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.usdRateDidUpdateNotification(_:)), name: rateUSDName, object: nil)
  }

  fileprivate func removeObserveNotifications() {
    let ethBalanceName = Notification.Name(kETHBalanceDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(self, name: ethBalanceName, object: nil)
    let tokenBalanceName = Notification.Name(kOtherBalanceDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(self, name: tokenBalanceName, object: nil)
    let rateUSDName = Notification.Name(kExchangeUSDRateNotificationKey)
    NotificationCenter.default.removeObserver(self, name: rateUSDName, object: nil)
  }

  @objc func tokenBalancesDidUpdateNotification(_ sender: Any) {
    self.rootViewController.updateBalance(usd: self.balanceCoordinator.totalBalanceInUSD, eth: self.balanceCoordinator.totalBalanceInETH)
    self.rootViewController.otherTokenBalanceDidUpdate(balances: self.balanceCoordinator.otherTokensBalance)
    self.selectTokenViewController.updateTokenBalances(self.balanceCoordinator.otherTokensBalance)
  }

  @objc func ethBalanceDidUpdateNotification(_ sender: Any) {
    self.rootViewController.updateBalance(usd: self.balanceCoordinator.totalBalanceInUSD, eth: self.balanceCoordinator.totalBalanceInETH)
    self.rootViewController.ethBalanceDidUpdate(balance: self.balanceCoordinator.ethBalance)
    self.selectTokenViewController.updateETHBalance(self.balanceCoordinator.ethBalance)
  }

  @objc func usdRateDidUpdateNotification(_ sender: Any) {
    self.rootViewController.updateBalance(usd: self.balanceCoordinator.totalBalanceInUSD, eth: self.balanceCoordinator.totalBalanceInETH)
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
          self.rootViewController.exchangeTokenDidReturn(result: result)
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
          self?.rootViewController.updateEstimateRateDidChange(
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
        self?.rootViewController.updateEstimateGasUsed(
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
    self.delegate?.userDidClickExitSession()
  }
}

extension KNExchangeTokenCoordinator: KNSelectTokenViewControllerDelegate {
  func selectTokenViewUserDidSelect(_ token: KNToken) {
    self.navigationController.popViewController(animated: true) {
      self.rootViewController.updateSelectedToken(token, isSource: self.isSelectingSourceToken)
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
