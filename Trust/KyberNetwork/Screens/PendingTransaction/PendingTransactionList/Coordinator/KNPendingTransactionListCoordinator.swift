// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNPendingTransactionListCoordinatorDelegate: class {
  func pendingTransactionListDidSelectExchangeNow()
  func pendingTransactionListDidSelectTransferNow()
  func pendingTransactionListDidSelectTransaction(_ transaction: Transaction)
}

class KNPendingTransactionListCoordinator: Coordinator {

  let navigationController: UINavigationController
  let storage: TransactionsStorage
  var coordinators: [Coordinator] = []

  weak var delegate: KNPendingTransactionListCoordinatorDelegate?

  fileprivate var timer: Timer?

  lazy var pendingTxListVC: KNPendingTransactionListViewController = {
    let controller = KNPendingTransactionListViewController(delegate: self, pendingTransactions: self.storage.pendingObjects)
    controller.modalPresentationStyle = .overCurrentContext
    return controller
  }()

  init(
    navigationController: UINavigationController,
    storage: TransactionsStorage
    ) {
    self.navigationController = navigationController
    self.storage = storage
  }

  func start() {
    self.navigationController.topViewController?.present(self.pendingTxListVC, animated: false, completion: {
      self.pendingTxListVC.updatePendingTransactions(self.storage.pendingObjects)
    })
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { [weak self] _ in
      self?.pendingTxListVC.updatePendingTransactions(self?.storage.pendingObjects ?? [])
    })
  }

  func stop(completion: @escaping () -> Void) {
    self.timer?.invalidate()
    self.timer = nil
    self.navigationController.topViewController?.dismiss(animated: false, completion: completion)
  }
}

extension KNPendingTransactionListCoordinator: KNPendingTransactionListViewControllerDelegate {

  func pendingTransactionListViewDidClose() {
    self.stop {}
  }

  func pendingTransactionListViewDidClickExchangeNow() {
    self.stop {
      self.delegate?.pendingTransactionListDidSelectExchangeNow()
    }
  }

  func pendingTransactionListViewDidClickTransferNow() {
    self.stop {
      self.delegate?.pendingTransactionListDidSelectTransferNow()
    }
  }

  func pendingTransactionListViewDidSelectTransaction(_ transaction: Transaction) {
    self.stop {
      self.delegate?.pendingTransactionListDidSelectTransaction(transaction)
    }
  }
}
