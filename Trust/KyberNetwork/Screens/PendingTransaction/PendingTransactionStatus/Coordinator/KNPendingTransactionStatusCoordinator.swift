// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

protocol KNPendingTransactionStatusCoordinatorDelegate: class {
  func pendingTransactionStatusCoordinatorDidClose()
}

class KNPendingTransactionStatusCoordinator: Coordinator {

  var transaction: Transaction
  weak var delegate: KNPendingTransactionStatusCoordinatorDelegate?

  var coordinators: [Coordinator] = []

  let navigationController: UINavigationController
  var rootViewController: KNPendingTransactionStatusViewController?

  init(
    navigationController: UINavigationController,
    transaction: Transaction,
    delegate: KNPendingTransactionStatusCoordinatorDelegate?
    ) {
    self.navigationController = navigationController
    self.transaction = transaction
    self.delegate = delegate
  }

  func start() {
    self.rootViewController = KNPendingTransactionStatusViewController(delegate: self, transaction: self.transaction)
    self.navigationController.present(self.rootViewController!, animated: true, completion: nil)
  }

  func stop(completion: @escaping () -> Void) {
    self.rootViewController?.dismiss(animated: true, completion: completion)
  }

  func updateTransaction(_ transaction: Transaction) {
    self.transaction = transaction
    self.rootViewController?.updateViewWithTransaction(self.transaction)
  }
}

extension KNPendingTransactionStatusCoordinator: KNPendingTransactionStatusViewControllerDelegate {
  func pendingTransactionStatusVCUserDidClickClose() {
    self.stop {
      self.delegate?.pendingTransactionStatusCoordinatorDidClose()
    }
  }

  func pendingTransactionStatusVCUserDidClickMoreDetails() {
    if let url = URL(string: KNEnvironment.default.etherScanIOURLString + "tx/\(self.transaction.id)") {
      let safariController = SFSafariViewController(url: url)
      self.rootViewController?.present(safariController, animated: true, completion: nil)
    }
  }
}
