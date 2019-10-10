// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

protocol KNHistoryCoordinatorDelegate: class {
  func historyCoordinatorDidClose()
}

class KNHistoryCoordinator: Coordinator {

  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  let navigationController: UINavigationController
  private(set) var session: KNSession

  var currentWallet: KNWalletObject

  var coordinators: [Coordinator] = []
  weak var delegate: KNHistoryCoordinatorDelegate?

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

  lazy var txDetailsCoordinator: KNTransactionDetailsCoordinator = {
    return KNTransactionDetailsCoordinator(
      navigationController: self.navigationController,
      transaction: nil,
      currentWallet: self.currentWallet
    )
  }()

  init(
    navigationController: UINavigationController,
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.session = session
    let address = self.session.wallet.address.description
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true) {
      let pendingTrans = self.session.transactionStorage.kyberPendingTransactions
      self.appCoordinatorTokensTransactionsDidUpdate(showLoading: true)
      self.appCoordinatorPendingTransactionDidUpdate(pendingTrans)
      self.rootViewController.coordinatorUpdateTokens(self.session.tokenStorage.tokens)
      self.session.transacionCoordinator?.forceFetchTokenTransactions()
    }
  }

  func stop() {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.historyCoordinatorDidClose()
    }
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    let address = self.session.wallet.address.description
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    self.appCoordinatorTokensTransactionsDidUpdate()
    self.rootViewController.coordinatorUpdateTokens(self.session.tokenStorage.tokens)
    let pendingTrans = self.session.transactionStorage.kyberPendingTransactions
    self.appCoordinatorPendingTransactionDidUpdate(pendingTrans)
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.rootViewController.coordinatorUpdateWalletObjects()
  }

  func appCoordinatorTokensTransactionsDidUpdate(showLoading: Bool = false) {
    var transactions: [Transaction] = Array(self.session.transactionStorage.transferNonePendingObjects.prefix(1000)).map({ return $0.clone() })
    let addressToSymbol: [String: String] = {
      var maps: [String: String] = [:]
      KNSupportedTokenStorage.shared.supportedTokens.forEach({
        maps[$0.contract.lowercased()] = $0.symbol
      })
      return maps
    }()
    let address = self.currentWallet.address
    if showLoading { self.navigationController.displayLoading() }
    DispatchQueue.global(qos: .background).async {
      transactions.sort(by: { return $0.id < $1.id })
      var processedTxs: [Transaction] = []
      var id = 0
      while id < transactions.count {
        if id == transactions.count - 1 {
          processedTxs.append(transactions[id])
          break
        }
        if transactions[id].id == transactions[id + 1].id {
          // count number of txs with same id
          var cnt = 2
          var tempId = id + 2
          while tempId < transactions.count && transactions[tempId].id == transactions[id].id {
            tempId += 1
            cnt += 1
          }
          if cnt > 2 {
            // more than 2 txs shared same hash
            tempId = id
            while id < transactions.count && transactions[id].id == transactions[tempId].id {
              processedTxs.append(transactions[id])
              id += 1
            }
            continue
          }
          // merge 2 transactions
          if let swap = Transaction.swapTransation(sendTx: transactions[id], receiveTx: transactions[id + 1], curWallet: address, addressToSymbol: addressToSymbol) {
            processedTxs.append(swap)
            id += 2
            continue
          }
        }
        processedTxs.append(transactions[id])
        id += 1
      }

      transactions = processedTxs.sorted(by: { return $0.date > $1.date })

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
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
        if showLoading { self.navigationController.hideLoading() }
        self.rootViewController.coordinatorUpdateCompletedTransactions(
          data: sectionData,
          dates: dates,
          currentWallet: self.currentWallet
        )
      })
    }
  }

  func appCoordinatorPendingTransactionDidUpdate(_ transactions: [KNTransaction]) {
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
        trans.append(tx.toTransaction())
        data[self.dateFormatter.string(from: tx.date)] = trans
      }
      return data
    }()

    self.rootViewController.coordinatorUpdatePendingTransaction(
      data: sectionData,
      dates: dates,
      currentWallet: self.currentWallet
    )
    self.txDetailsCoordinator.updatePendingTransactions(transactions, currentWallet: self.currentWallet)
  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent) {
    switch event {
    case .selectTransaction(let transaction):
      self.txDetailsCoordinator.update(
        transaction: transaction,
        currentWallet: self.currentWallet
      )
      self.txDetailsCoordinator.start()
    case .dismiss:
      self.stop()
    }
  }

  fileprivate func openEtherScanForTransaction(with hash: String) {
    if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.rootViewController.openSafari(with: url)
    }
  }
}
