// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore

class KNTransferTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession
  let balanceCoordinator: KNBalanceCoordinator
  let tokens: [KNToken] = KNJSONLoaderUtil.shared.tokens

  weak var delegate: KNSessionDelegate?

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNTransferTokenViewController = {
    let controller = KNTransferTokenViewController(delegate: self)
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
  }

  func stop() {
  }

  func tokenBalancesDidUpdateNotification(_ sender: Any) {
    self.rootViewController.coordinatorUpdateUSDBalance(usd: self.balanceCoordinator.totalBalanceInUSD)
    self.rootViewController.coordinatorOtherTokenBalanceDidUpdate(balances: self.balanceCoordinator.otherTokensBalance)
    self.selectTokenViewController.updateTokenBalances(self.balanceCoordinator.otherTokensBalance)
  }

  func ethBalanceDidUpdateNotification(_ sender: Any) {
    self.rootViewController.coordinatorUpdateUSDBalance(usd: self.balanceCoordinator.totalBalanceInUSD)
    self.rootViewController.coordinatorETHBalanceDidUpdate(balance: self.balanceCoordinator.ethBalance)
    self.selectTokenViewController.updateETHBalance(self.balanceCoordinator.ethBalance)
  }

  func usdRateDidUpdateNotification(_ sender: Any) {
    self.rootViewController.coordinatorUpdateUSDBalance(usd: self.balanceCoordinator.totalBalanceInUSD)
  }

  fileprivate func didConfirmTransfer(_ transaction: UnconfirmedTransaction) {
    self.navigationController.topViewController?.displayLoading()
    KNTransactionCoordinator.requestDataPrepareForTransferTransaction(
      transaction,
      provider: self.session.externalProvider) { [weak self] result in
      guard let `self` = self else { return }
        switch result {
        case .success(let newTx):
          if let newTransaction = newTx {
            self.session.externalProvider.transfer(transaction: newTransaction, completion: { [weak self] transferResult in
              guard let `self` = self else { return }
              self.navigationController.topViewController?.hideLoading()
              switch transferResult {
              case .success(let txHash):
                let tx: Transaction = newTransaction.toTransaction(
                  wallet: self.session.wallet,
                  hash: txHash,
                  nounce: self.session.externalProvider.minTxCount
                )
                self.session.addNewPendingTransaction(tx)
              case .failure:
                self.rootViewController.coordinatorTransferDidReturn(result: transferResult)
              }
            })
          } else {
            self.navigationController.topViewController?.hideLoading()
            self.navigationController.topViewController?.showInsufficientBalanceAlert()
          }
        case .failure(let error):
          self.navigationController.topViewController?.hideLoading()
          self.navigationController.displayError(error: error.error)
        }
    }
  }

  func appCoordinatorShouldOpenTransferForToken(_ token: KNToken) {
    self.rootViewController.coordinatorSelectedTokenDidUpdate(token)
    self.rootViewController.tabBarController?.selectedIndex = 1
  }
}

extension KNTransferTokenCoordinator: KNTransferTokenViewControllerDelegate {
  func transferTokenViewControllerDidClickTransfer(transaction: UnconfirmedTransaction) {
    let transactionType = KNTransactionType.transfer(transaction)
    self.confirmTransactionViewController = KNConfirmTransactionViewController(
      delegate: self,
      type: transactionType
    )
    self.confirmTransactionViewController.modalPresentationStyle = .overCurrentContext
    self.navigationController.topViewController?.present(self.confirmTransactionViewController, animated: false, completion: nil)
  }

  func transferTokenViewControllerDidClickTokenButton(_ selectedToken: KNToken) {
    self.navigationController.pushViewController(self.selectTokenViewController, animated: true)
  }

  func transferTokenViewControllerShouldUpdateEstimatedGas(from token: KNToken, to address: String?, amount: BigInt) {
    let type: TransferType = {
      if token.isETH { return .ether(destination: Address(string: address ?? "")) }
      let tokenObject = TokenObject(
        contract: token.address,
        name: token.name,
        symbol: token.symbol,
        decimals: token.decimal,
        value: amount.fullString(decimals: token.decimal),
        isCustom: false,
        isDisabled: false)
      return TransferType.token(tokenObject)
    }()

    let transaction = UnconfirmedTransaction(
      transferType: type,
      value: amount,
      to: Address(string: address ?? ""),
      data: nil,
      gasLimit: .none,
      gasPrice: .none,
      nonce: .none
    )
    self.session.externalProvider.getEstimateGasLimit(for: transaction) { [weak self] result in
      if case .success(let gasLimit) = result {
        self?.rootViewController.coordinatorEstimateGasUsedDidUpdate(
          token: token,
          amount: amount,
          estimate: gasLimit
        )
      }
    }
  }

  func transferTokenViewControllerDidClickPendingTransaction() {
    self.pendingTransactionListCoordinator.start()
  }

  func transferTokenViewControllerDidExit() {
    self.stop()
    self.delegate?.userDidClickExitSession()
  }
}

extension KNTransferTokenCoordinator: KNSelectTokenViewControllerDelegate {
  func selectTokenViewUserDidSelect(_ token: KNToken) {
    self.navigationController.popViewController(animated: true) {
      self.rootViewController.coordinatorSelectedTokenDidUpdate(token)
    }
  }
}

extension KNTransferTokenCoordinator: KNConfirmTransactionViewControllerDelegate {
  func confirmTransactionDidCancel() {
    self.navigationController.topViewController?.dismiss(animated: false, completion: {
      self.confirmTransactionViewController = nil
    })
  }

  func confirmTransactionDidConfirm(type: KNTransactionType) {
    self.navigationController.topViewController?.dismiss(animated: false, completion: {
      self.confirmTransactionViewController = nil
      if case .transfer(let transaction) = type {
        self.didConfirmTransfer(transaction)
      }
    })
  }
}

extension KNTransferTokenCoordinator: KNPendingTransactionListCoordinatorDelegate {
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
