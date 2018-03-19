// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import APIKit
import JSONRPCKit
import JavaScriptKit
import Result
import BigInt

class KNTransactionCoordinator {

  static let didUpdateNotificationKey = "kTransactionDidUpdateNotificationKey"

  let storage: TransactionsStorage
  let externalProvider: KNExternalProvider
  fileprivate var timer: Timer?

  init(storage: TransactionsStorage, externalProvider: KNExternalProvider) {
    self.storage = storage
    self.externalProvider = externalProvider
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

  func updatePendingTranscation(_ transaction: Transaction) {
    self.checkTransactionReceipt(transaction) { [weak self] error in
      if error == nil { return }
      guard let `self` = self else { return }
      self.externalProvider.getTransactionByHash(transaction.id, completion: { [weak self] sessionError in
        guard let `self` = self else { return }
        if let trans = self.storage.get(forPrimaryKey: transaction.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        if let error = sessionError {
          // Failure
          if case .responseError(let err) = error, let respError = err as? JSONRPCError {
            switch respError {
            case .responseError(let code, let message, _):
              NSLog("Fetch pending transaction with hash \(transaction.id) failed with error code \(code) and message \(message)")
              self.storage.delete([transaction])
            case .resultObjectParseError:
              if transaction.date.addingTimeInterval(60) < Date() {
                self.updateTransactionStateIfNeeded(transaction, state: .failed)
              }
            default: break
            }
          }
        } else {
          // Success
          if transaction.date.addingTimeInterval(60) < Date() {
            self.updateTransactionStateIfNeeded(transaction, state: .completed)
          }
        }
      })
    }
  }

  fileprivate func checkTransactionReceipt(_ transaction: Transaction, completion: @escaping (Error?) -> Void) {
    self.externalProvider.getReceipt(for: transaction) { [weak self] result in
      switch result {
      case .success(let newTx):
        if let trans = self?.storage.get(forPrimaryKey: newTx.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        self?.storage.add([newTx])
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: newTx.id,
          userInfo: nil
        )
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }

  fileprivate func updateTransactionStateIfNeeded(_ transaction: Transaction, state: TransactionState) {
    if let trans = self.storage.get(forPrimaryKey: transaction.id), trans.state != .pending { return }
    self.storage.update(state: state, for: transaction)
    KNNotificationUtil.postNotification(
      for: KNTransactionCoordinator.didUpdateNotificationKey,
      object: transaction.id,
      userInfo: nil
    )
  }

  func stopUpdatingPendingTransactions() {
    self.timer?.invalidate()
    self.timer = nil
  }
}
