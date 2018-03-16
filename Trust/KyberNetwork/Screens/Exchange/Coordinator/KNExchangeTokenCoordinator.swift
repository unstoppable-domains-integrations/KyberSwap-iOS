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
    controller.applyBaseGradientBackground()
    return controller
  }()

  lazy var selectTokenViewController: KNSelectTokenViewController = {
    let controller = KNSelectTokenViewController(delegate: self, availableTokens: self.tokens)
    return controller
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession,
    balanceCoordinator: KNBalanceCoordinator
    ) {
    self.navigationController = navigationController
    self.session = session
    self.balanceCoordinator = balanceCoordinator
    self.navigationController.applyStyle()
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.addObserveNotifications()
  }

  func stop() {
    self.removeObserveNotifications()
  }

  fileprivate func addObserveNotifications() {
    let name = Notification.Name(KNBalanceCoordinator.KNBalanceNotificationKeys.ethBalanceDidUpdate.rawValue)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.ethBalanceDidUpdateNotification(_:)),
      name: name,
      object: nil
    )
    let tokenBalanceName = Notification.Name(KNBalanceCoordinator.KNBalanceNotificationKeys.otherTokensBalanceDidUpdate.rawValue)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenBalancesDidUpdateNotification(_:)),
      name: tokenBalanceName,
      object: nil
    )
    let rateUSDName = Notification.Name(KNRateCoordinator.KNRateNotificationKeys.exchangeRateUSDDidUpdateKey.rawValue)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.usdRateDidUpdateNotification(_:)), name: rateUSDName, object: nil)
  }

  fileprivate func removeObserveNotifications() {
    let name = Notification.Name(KNBalanceCoordinator.KNBalanceNotificationKeys.ethBalanceDidUpdate.rawValue)
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
    let tokenBalanceName = Notification.Name(KNBalanceCoordinator.KNBalanceNotificationKeys.otherTokensBalanceDidUpdate.rawValue)
    NotificationCenter.default.removeObserver(self, name: tokenBalanceName, object: nil)
    let rateUSDName = Notification.Name(KNRateCoordinator.KNRateNotificationKeys.exchangeRateUSDDidUpdateKey.rawValue)
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

  fileprivate func sendExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    self.session.externalProvider.exchange(exchange: exchangeTransaction) { [weak self] result in
      self?.navigationController.topViewController?.hideLoading()
      self?.rootViewController.exchangeTokenDidReturn(result: result)
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

  func exchangeTokenDidClickExchange(exchangeTransaction: KNDraftExchangeTransaction, expectedRate: BigInt) {
    // TODO (Mike): Show confirm view
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

  func exchangeTokenUserDidClickSelectTokenButton(source: KNToken, dest: KNToken, isSource: Bool) {
    self.isSelectingSourceToken = isSource
    self.navigationController.pushViewController(self.selectTokenViewController, animated: true)
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
