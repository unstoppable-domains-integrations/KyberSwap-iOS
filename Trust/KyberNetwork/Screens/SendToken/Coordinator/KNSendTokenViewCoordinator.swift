// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNSendTokenViewCoordinatorDelegate: class {
  func sendTokenCoordinatorDidPressBack()
}

class KNSendTokenViewCoordinator: Coordinator {

  let navigationController: UINavigationController
  fileprivate var session: KNSession
  var coordinators: [Coordinator] = []
  var balances: [String: Balance] = [:]
  fileprivate var from: TokenObject

  weak var delegate: KNSendTokenViewCoordinatorDelegate?

  lazy var rootViewController: KNSendTokenViewController = {
    let viewModel = KNSendTokenViewModel(
      from: self.from,
      balance: self.balances[self.from.contract]
    )
    let controller = KNSendTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var searchTokensVC: KNSearchTokenViewController = {
    let viewModel = KNSearchTokenViewModel(supportedTokens: KNSupportedTokenStorage.shared.supportedTokens)
    let controller = KNSearchTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var confirmTransactionViewController: KNConfirmTransactionViewController!

  init(
    navigationController: UINavigationController,
    session: KNSession,
    balances: [String: Balance],
    from: TokenObject = KNSupportedTokenStorage.shared.ethToken
    ) {
    self.navigationController = navigationController
    self.session = session
    self.balances = balances
    self.from = from
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }
}

// MARK: Update from coordinator
extension KNSendTokenViewCoordinator {
  func coordinatorTokenBalancesDidUpdate(balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    self.rootViewController.coordinatorUpdateBalances(self.balances)
  }

  func coordinatorETHBalanceDidUpdate(ethBalance: Balance) {
    let eth = KNSupportedTokenStorage.shared.ethToken
    self.balances[eth.contract] = ethBalance
    self.rootViewController.coordinatorUpdateBalances(self.balances)
  }

  func coordinatorShouldOpenSend(from token: TokenObject) {
    self.rootViewController.coordinatorDidUpdateSendToken(token, balance: self.balances[token.contract])
  }

  func coordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.searchTokensVC.updateListSupportedTokens(tokenObjects)
  }
}

// MARK: Send Token View Controller Delegate
extension KNSendTokenViewCoordinator: KNSendTokenViewControllerDelegate {
  func sendTokenViewControllerDidPressBack(sender: KNSendTokenViewController) {
    self.stop()
  }

  func sendTokenViewControllerDidPressGasPrice(sender: KNSendTokenViewController, gasPrice: BigInt, estGasLimit: BigInt) {
    let setGasPriceVC: KNSetGasPriceViewController = {
      let viewModel = KNSetGasPriceViewModel(gasPrice: gasPrice, estGasLimit: estGasLimit)
      let controller = KNSetGasPriceViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(setGasPriceVC, animated: true)
  }

  func sendTokenViewControllerUpdateEstimatedGasLimit(sender: KNSendTokenViewController, transaction: UnconfirmedTransaction) {
    self.session.externalProvider.getEstimateGasLimit(
    for: transaction) { [weak self] result in
      if case .success(let gasLimit) = result {
        self?.rootViewController.coordinatorUpdateEstimatedGasLimit(
          gasLimit,
          from: transaction.transferType.tokenObject(),
          amount: transaction.value
        )
      }
    }
  }

  func sendTokenViewControllerDidPressToken(sender: KNSendTokenViewController, selectedToken: TokenObject) {
    self.searchTokensVC.updateListSupportedTokens(KNSupportedTokenStorage.shared.supportedTokens)
    self.navigationController.pushViewController(self.searchTokensVC, animated: true)
  }

  func sendTokenViewControllerDidPressSend(sender: KNSendTokenViewController, transaction: UnconfirmedTransaction) {
    let transactionType = KNTransactionType.transfer(transaction)
    self.confirmTransactionViewController = KNConfirmTransactionViewController(
      delegate: self,
      type: transactionType
    )
    self.confirmTransactionViewController.modalPresentationStyle = .overCurrentContext
    self.confirmTransactionViewController.modalTransitionStyle = .crossDissolve
    self.navigationController.topViewController?.present(
      self.confirmTransactionViewController,
      animated: false,
      completion: nil
    )
  }
}

// MARK: Search Token Delegate
extension KNSendTokenViewCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewControllerDidCancel() {
    self.navigationController.popViewController(animated: true)
  }

  func searchTokenViewControllerDidSelect(token: TokenObject) {
    self.navigationController.popViewController(animated: true) {
      let balance = self.balances[token.contract]
      self.rootViewController.coordinatorDidUpdateSendToken(token, balance: balance)
    }
  }
}

// MARK: Confirm Transaction Delegate
extension KNSendTokenViewCoordinator: KNConfirmTransactionViewControllerDelegate {
  func confirmTransactionDidCancel() {
    self.navigationController.topViewController?.dismiss(animated: true, completion: {
      self.confirmTransactionViewController = nil
    })
  }

  func confirmTransactionDidConfirm(type: KNTransactionType) {
    self.navigationController.topViewController?.dismiss(animated: true, completion: {
      self.confirmTransactionViewController = nil
      if case .transfer(let transaction) = type {
        self.didConfirmTransfer(transaction)
      }
    })
  }
}

// MARK: Set Gas Price Delegate
extension KNSendTokenViewCoordinator: KNSetGasPriceViewControllerDelegate {
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?) {
    self.navigationController.popViewController(animated: true) {
      if let gasPrice = gasPrice { self.rootViewController.coordinatorUpdateGasPrice(gasPrice) }
    }
  }
}

// MARK: Network requests
extension KNSendTokenViewCoordinator {
  fileprivate func didConfirmTransfer(_ transaction: UnconfirmedTransaction) {
    self.rootViewController.coordinatorSendTokenUserDidConfirmTransaction()
    KNNotificationUtil.postNotification(for: kTransactionDidUpdateNotificationKey)
    // send transaction request
    self.session.externalProvider.transfer(transaction: transaction, completion: { [weak self] sendResult in
      guard let `self` = self else { return }
      switch sendResult {
      case .success(let txHash):
        let tx: Transaction = transaction.toTransaction(
          wallet: self.session.wallet,
          hash: txHash,
          nounce: self.session.externalProvider.minTxCount
        )
        self.session.addNewPendingTransaction(tx)
      case .failure(let error):
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
      }
    })
  }
}
