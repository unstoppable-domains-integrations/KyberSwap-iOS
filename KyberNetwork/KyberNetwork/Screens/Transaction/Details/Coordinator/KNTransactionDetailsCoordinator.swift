// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

class KNTransactionDetailsCoordinator: Coordinator {

  let navigationController: UINavigationController
  let etherScanURL: String = KNEnvironment.default.etherScanIOURLString
  fileprivate var transaction: Transaction?
  fileprivate var currentWallet: KNWalletObject
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNTransactionDetailsViewController = {
    let viewModel = KNTransactionDetailsViewModel(
      transaction: self.transaction,
      currentWallet: self.currentWallet
    )
    let controller = KNTransactionDetailsViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(
    navigationController: UINavigationController,
    transaction: Transaction?,
    currentWallet: KNWalletObject
    ) {
    self.navigationController = navigationController
    self.transaction = transaction
    self.currentWallet = currentWallet
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }

  func update(transaction: Transaction, currentWallet: KNWalletObject) {
    self.transaction = transaction
    self.rootViewController.coordinator(update: transaction, currentWallet: currentWallet)
  }

  func updatePendingTransactions(_ transactions: [KNTransaction], currentWallet: KNWalletObject) {
    guard let tran = transactions.map({ $0.toTransaction() }).first(where: { $0.compoundKey == (self.transaction?.compoundKey ?? "") }) else {
      if let topVC = self.navigationController.topViewController, topVC is KNTransactionDetailsViewController {
        self.stop()
      }
      return
    }
    self.rootViewController.coordinator(update: tran, currentWallet: currentWallet)
  }
}

extension KNTransactionDetailsCoordinator: KNTransactionDetailsViewControllerDelegate {
  func transactionDetailsViewController(_ controller: KNTransactionDetailsViewController, run event: KNTransactionDetailsViewEvent) {
    switch event {
    case .back: self.stop()
    case .openEtherScan:
      let urlString = "\(self.etherScanURL)tx/\(self.transaction?.id ?? "")"
      self.rootViewController.openSafari(with: urlString)
    }
  }
}
