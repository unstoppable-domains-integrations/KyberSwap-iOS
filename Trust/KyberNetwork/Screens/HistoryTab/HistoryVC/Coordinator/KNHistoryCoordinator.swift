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

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNHistoryViewController = {
    let controller = KNHistoryViewController()
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
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true) {
      if !self.session.transactionStorage.historyTransactions.isEmpty {
        self.historyTransactionsDidUpdate(nil)
      }
      self.appCoordinatorTokensTransactionsDidUpdate()
      self.addObserveNotification()
    }
  }

  fileprivate func addObserveNotification() {
    let name = Notification.Name(kTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.historyTransactionsDidUpdate(_:)),
      name: name,
      object: nil
    )
  }

  func stop() {
    self.removeObserveNotification()
    self.navigationController.popViewController(animated: true)
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    self.historyTransactionsDidUpdate(nil)
    self.appCoordinatorTokensTransactionsDidUpdate()
  }

  fileprivate func removeObserveNotification() {
    let name = Notification.Name(kTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: name,
      object: nil
    )
  }

  @objc func historyTransactionsDidUpdate(_ sender: Any?) {
    let transactions: [KNHistoryTransaction] = self.session.transactionStorage.historyTransactions

    let dates: [String] = {
      let dates = transactions.map { return self.dateFormatter.string(from: Date(timeIntervalSince1970: Double($0.blockTimestamp))) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [KNHistoryTransaction]] = {
      var data: [String: [KNHistoryTransaction]] = [:]
      transactions.forEach { tx in
        let date = Date(timeIntervalSince1970: Double(tx.blockTimestamp))
        var trans = data[self.dateFormatter.string(from: date)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: date)] = trans
      }
      return data
    }()

    self.rootViewController.coordinatorUpdateHistoryTransactions(
      data: sectionData,
      dates: dates,
      ownerAddress: self.session.wallet.address.description
    )
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    let transactions: [KNTokenTransaction] = self.session.transactionStorage.tokenTransactions

    let dates: [String] = {
      let dates = transactions.map { return self.dateFormatter.string(from: $0.date) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [KNTokenTransaction]] = {
      var data: [String: [KNTokenTransaction]] = [:]
      transactions.forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: tx.date)] = trans
      }
      return data
    }()
    self.rootViewController.coordinatorUpdateTokenTransactions(
      data: sectionData,
      dates: dates,
      ownerAddress: self.session.wallet.address.description
    )
  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent) {
    switch event {
    case .selectTokenTransaction(let transaction):
      self.openEtherScanForTransaction(with: transaction.id)
    case .selectHistoryTransaction(let transaction):
      self.openEtherScanForTransaction(with: transaction.id)
    case .dismiss:
      self.stop()
    }
  }

  fileprivate func openEtherScanForTransaction(with hash: String) {
    if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      let controller = SFSafariViewController(url: url)
      self.navigationController.topViewController?.present(controller, animated: true, completion: nil)
    }
  }
}
