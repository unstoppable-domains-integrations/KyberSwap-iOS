// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNSendTokenViewCoordinator: Coordinator {

  let navigationController: UINavigationController
  fileprivate var session: KNSession
  var coordinators: [Coordinator] = []
  var balances: [String: Balance] = [:]
  fileprivate var from: TokenObject

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

  lazy var addContactVC: KNNewContactViewController = {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: "")
    let controller = KNNewContactViewController(viewModel: viewModel)
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

  func coordinatorGasPriceCachedDidUpdate() {
    self.rootViewController.coordinatorUpdateGasPriceCached()
  }
}

// MARK: Send Token View Controller Delegate
extension KNSendTokenViewCoordinator: KNSendTokenViewControllerDelegate {
  func sendTokenViewController(_ controller: KNSendTokenViewController, run event: KNSendTokenViewEvent) {
    switch event {
    case .back: self.stop()
    case .setGasPrice(let gasPrice, let gasLimit):
      self.openSetGasPrice(gasPrice: gasPrice, estGasLimit: gasLimit)
    case .estimateGas(let transaction):
      self.estimateGasLimit(for: transaction)
    case .searchToken(let selectedToken):
      self.openSearchToken(selectedToken: selectedToken)
    case .send(let transaction):
      self.send(transaction: transaction)
    case .addContact(let address):
      self.openNewContact(address: address)
    }
  }

  fileprivate func openSetGasPrice(gasPrice: BigInt, estGasLimit: BigInt) {
    let setGasPriceVC: KNSetGasPriceViewController = {
      let viewModel = KNSetGasPriceViewModel(gasPrice: gasPrice, estGasLimit: estGasLimit)
      let controller = KNSetGasPriceViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(setGasPriceVC, animated: true)
  }

  fileprivate func estimateGasLimit(for transaction: UnconfirmedTransaction) {
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

  fileprivate func openSearchToken(selectedToken: TokenObject) {
    let tokens = KNSupportedTokenStorage.shared.supportedTokens
    self.searchTokensVC.updateListSupportedTokens(tokens)
    self.navigationController.present(self.searchTokensVC, animated: true, completion: nil)
  }

  fileprivate func send(transaction: UnconfirmedTransaction) {
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

  fileprivate func openNewContact(address: String) {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: address)
    self.addContactVC.updateView(viewModel: viewModel)
    self.navigationController.pushViewController(self.addContactVC, animated: true)
  }
}

// MARK: Search Token Delegate
extension KNSendTokenViewCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    self.searchTokensVC.dismiss(animated: true) {
      if case .select(let token) = event {
        let balance = self.balances[token.contract]
        self.rootViewController.coordinatorDidUpdateSendToken(token, balance: balance)
      }
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
      self.rootViewController.coordinatorUpdateGasPrice(gasPrice)
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

extension KNSendTokenViewCoordinator: KNSaveContactViewControllerDelegate {
  func saveContactViewController(_ controller: KNSaveContactViewController, run event: KNSaveContactViewEvent) {
    self.navigationController.dismiss(animated: true) {
      if case .save(let address, let name) = event {
        let contact = KNContact(address: address, name: name)
        KNContactStorage.shared.update(contacts: [contact])
        KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
      }
    }
  }
}

extension KNSendTokenViewCoordinator: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    switch event {
    case .dismiss:
      self.navigationController.popViewController(animated: true)
    }
  }
}
