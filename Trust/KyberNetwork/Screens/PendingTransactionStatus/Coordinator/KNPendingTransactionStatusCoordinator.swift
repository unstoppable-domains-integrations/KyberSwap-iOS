// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

class KNPendingTransactionStatusCoordinator: Coordinator {

  let newWindow: UIWindow
  var transaction: Transaction

  var coordinators: [Coordinator] = []

  var rootViewController: KNPendingTransactionStatusViewController?

  init(transaction: Transaction) {
    self.transaction = transaction
    self.newWindow = UIWindow()
    self.newWindow.frame = UIScreen.main.bounds
    self.newWindow.windowLevel = UIWindowLevelAlert + 1.0
    self.newWindow.isHidden = true
  }

  func start() {
    self.rootViewController = KNPendingTransactionStatusViewController(delegate: self, transaction: self.transaction)
    self.newWindow.rootViewController = self.rootViewController
    self.newWindow.makeKeyAndVisible()
    self.rootViewController?.updateViewWithTransaction(transaction)
    self.newWindow.isHidden = false
  }

  func stop(completion: @escaping () -> Void) {
    self.newWindow.isHidden = true
    completion()
  }

  func updateTransaction(_ transaction: Transaction) {
    self.transaction = transaction
    if self.newWindow.isHidden {
      self.start()
    } else {
      self.rootViewController?.updateViewWithTransaction(self.transaction)
    }
  }
}

extension KNPendingTransactionStatusCoordinator: KNPendingTransactionStatusViewControllerDelegate {
  func pendingTransactionStatusVCUserDidClickClose() {
    self.stop {}
  }

  func pendingTransactionStatusVCUserDidClickMoreDetails() {
    if let url = URL(string: KNEnvironment.default.etherScanIOURLString + "tx/\(self.transaction.id)") {
      let safariController = SFSafariViewController(url: url)
      self.rootViewController?.present(safariController, animated: true, completion: nil)
    }
  }
}
