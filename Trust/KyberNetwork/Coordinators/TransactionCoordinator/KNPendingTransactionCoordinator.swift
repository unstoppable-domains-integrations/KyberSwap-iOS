// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import APIKit
import JSONRPCKit

enum KNPendingTxNotificationKeys: String {
  case completed
  case failed
}

class KNPendingTransactionCoordinator {

  let storage: TransactionsStorage
  fileprivate var timer: Timer?

  init(storage: TransactionsStorage) {
    self.storage = storage
  }

  func startUpdatingPendingTransactions() {
    self.timer?.invalidate()
    self.timer = nil
    self.shouldUpdatePendingTransaction(nil)
    self.timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { [weak self] timer in
      self?.shouldUpdatePendingTransaction(timer)
    })
  }

  @objc func shouldUpdatePendingTransaction(_ sender: Any?) {
    self.storage.pendingObjects.forEach { self.updatePendingTranscation($0) }
  }

  fileprivate func updatePendingTranscation(_ transaction: Transaction) {
    let request = GetTransactionRequest(hash: transaction.id)
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success://(let parsedTx):
        if transaction.date.addingTimeInterval(60) < Date() {
          self.storage.update(state: .completed, for: transaction)
          KNNotificationUtil.postNotification(for: KNPendingTxNotificationKeys.completed.rawValue, object: transaction, userInfo: nil)
        }
      case .failure(let error):
        switch error {
        case .responseError(let err):
          guard let respError = err as? JSONRPCError else {
            return
          }
          switch respError {
          case .responseError(let code, let message, _):
            NSLog("Fetch pending transaction with hash \(transaction.id) failed with error code \(code) and message \(message)")
            self.storage.delete([transaction])
          case .resultObjectParseError:
            if transaction.date.addingTimeInterval(60) < Date() {
              self.storage.update(state: .failed, for: transaction)
              KNNotificationUtil.postNotification(for: KNPendingTxNotificationKeys.failed.rawValue, object: transaction, userInfo: nil)
            }
          default: break
          }
        default: break
        }
      }
    }
  }

  func stopUpdatingPendingTransactions() {
    self.timer?.invalidate()
    self.timer = nil
  }
}
