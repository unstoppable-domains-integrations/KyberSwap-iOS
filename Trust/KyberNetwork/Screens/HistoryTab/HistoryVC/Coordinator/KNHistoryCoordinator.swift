// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

class KNHistoryCoordinator: Coordinator {

  fileprivate lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy MMM dd"
    return formatter
  }()
  let navigationController: UINavigationController
  private(set) var session: KNSession

  var currentWallet: KNWalletObject

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNHistoryViewController = {
    let viewModel = KNHistoryViewModel(
      completedTxData: [:],
      completedTxHeaders: [],
      pendingTxData: [:],
      pendingTxHeaders: [],
      currentWallet: self.currentWallet
    )
    let controller = KNHistoryViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(
    navigationController: UINavigationController,
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.session = session
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: self.session.wallet.address.description)!
  }

  func start() {
    self.appCoordinatorTokensTransactionsDidUpdate()
    let pendingTrans = self.session.transactionStorage.pendingObjects
    self.appCoordinatorPendingTransactionDidUpdate(pendingTrans)
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: self.session.wallet.address.description)!
    self.appCoordinatorTokensTransactionsDidUpdate()
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    let transactions: [Transaction] = self.session.transactionStorage.nonePendingObjects

    let dates: [String] = {
      let dates = transactions.map { return self.dateFormatter.string(from: $0.date) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [Transaction]] = {
      var data: [String: [Transaction]] = [:]
      transactions.forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: tx.date)] = trans
      }
      return data
    }()
    self.rootViewController.coordinatorUpdateCompletedTransactions(
      data: sectionData,
      dates: dates,
      currentWallet: self.currentWallet
    )
  }

  func appCoordinatorPendingTransactionDidUpdate(_ transactions: [Transaction]) {
    let dates: [String] = {
      let dates = transactions.map { return self.dateFormatter.string(from: $0.date) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [Transaction]] = {
      var data: [String: [Transaction]] = [:]
      transactions.forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: tx.date)] = trans
      }
      return data
    }()

    self.rootViewController.coordinatorUpdatePendingTransaction(
      data: sectionData,
      dates: dates,
      currentWallet: self.currentWallet
    )
  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent) {
    switch event {
    case .selectTransaction(let transaction):
      self.openEtherScanForTransaction(with: transaction.id)
    case .dismiss:
      self.stop()
    }
  }

  fileprivate func openEtherScanForTransaction(with hash: String) {
    if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      let controller = SFSafariViewController(url: url)
      self.rootViewController.present(controller, animated: true, completion: nil)
    }
  }
}
