// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import Result

/*
 Handling notification from many fetchers, views, ...
 */
extension KNAppCoordinator {
  func addObserveNotificationFromSession() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.transactionStateDidUpdate(_:)),
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
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
    let tokenTxListName = Notification.Name(kTokenTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenTransactionListDidUpdate(_:)),
      name: tokenTxListName,
      object: nil
    )
    let tokenObjectListName = Notification.Name(kTokenObjectListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: tokenObjectListName,
      object: nil
    )
    let coinTickerName = Notification.Name(kCoinTickersDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.coinTickerDidUpdate(_:)),
      name: coinTickerName,
      object: nil
    )
  }

  func addInternalObserveNotification() {
    let rateTokensName = Notification.Name(kExchangeTokenRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateTokenDidUpdateNotification(_:)),
      name: rateTokensName,
      object: nil)
    let rateUSDName = Notification.Name(kExchangeUSDRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateUSDDidUpdateNotification(_:)),
      name: rateUSDName,
      object: nil
    )
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: supportedTokensName,
      object: nil
    )
    let gasPriceName = Notification.Name(kGasPriceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.gasPriceCachedDidUpdate(_:)),
      name: gasPriceName,
      object: nil
    )
  }

  func removeObserveNotificationFromSession() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kETHBalanceDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kOtherBalanceDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTokenTransactionListDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTokenObjectListDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kCoinTickersDidUpdateNotificationKey),
      object: self
    )
  }

  func removeInternalObserveNotification() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kExchangeTokenRateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kExchangeUSDRateNotificationKey),
      object: nil
    )
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: supportedTokensName,
      object: nil
    )
    let gasPriceName = Notification.Name(kGasPriceDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: gasPriceName,
      object: nil
    )
  }

  @objc func exchangeRateTokenDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let balanceCoordinator = self.balanceCoordinator else { return }

    self.balanceTabCoordinator.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: balanceCoordinator.totalBalanceInUSD,
      totalBalanceInETH: balanceCoordinator.totalBalanceInETH
    )
  }

  @objc func exchangeRateUSDDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let balanceCoordinator = self.balanceCoordinator else { return }
    let totalUSD: BigInt = balanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = balanceCoordinator.totalBalanceInETH

    self.exchangeCoordinator?.appCoordinatorUSDRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )
    self.balanceTabCoordinator.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )
  }

  @objc func ethBalanceDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let balanceCoordinator = self.balanceCoordinator else { return }
    let totalUSD: BigInt = balanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = balanceCoordinator.totalBalanceInETH
    let ethBalance: Balance = balanceCoordinator.ethBalance

    self.exchangeCoordinator?.appCoordinatorETHBalanceDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      ethBalance: ethBalance
    )
    self.balanceTabCoordinator.appCoordinatorETHBalanceDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      ethBalance: ethBalance
    )
  }

  @objc func tokenBalancesDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let balanceCoordinator = self.balanceCoordinator else { return }
    let totalUSD: BigInt = balanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = balanceCoordinator.totalBalanceInETH
    let otherTokensBalance: [String: Balance] = balanceCoordinator.otherTokensBalance

    self.exchangeCoordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )
    self.balanceTabCoordinator.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )
  }

  @objc func transactionStateDidUpdate(_ sender: Notification) {
    if self.session == nil { return }
    let transaction: Transaction? = {
      if let txHash = sender.object as? String {
        return self.session.transactionStorage.get(forPrimaryKey: txHash)
      }
      return nil
    }()
    let error: AnyError? = sender.object as? AnyError
    if self.transactionStatusCoordinator == nil {
      self.transactionStatusCoordinator = KNTransactionStatusCoordinator(
        navigationController: self.navigationController,
        transaction: transaction,
        delegate: self
      )
      self.transactionStatusCoordinator.start()
    }
    self.transactionStatusCoordinator.updateTransaction(transaction, error: error?.prettyError)
    // Force load new token transactions to faster updating history view
    if let tran = transaction, tran.state == .completed {
      self.session.transacionCoordinator?.forceFetchTokenTransactions()
    }
    let transactions = self.session.transactionStorage.pendingObjects
    self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
    self.balanceTabCoordinator.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
  }

  @objc func tokenTransactionListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  @objc func tokenObjectListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.session.tokenStorage.addKyberSupportedTokens()
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
    self.balanceTabCoordinator.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.exchangeCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  @objc func coinTickerDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.balanceTabCoordinator.appCoordinatorCoinTickerDidUpdate()
  }

  @objc func gasPriceCachedDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorGasPriceCachedDidUpdate()
    self.balanceTabCoordinator.appCoordinatorGasPriceCachedDidUpdate()
  }
}
