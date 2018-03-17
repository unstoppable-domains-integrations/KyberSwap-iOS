// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import APIKit
import JSONRPCKit
import Result

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

  func updatePendingTranscation(_ transaction: Transaction) {
    self.checkTransactionReceipt(transaction) { [weak self] error in
      if error == nil { return }
      guard let `self` = self else { return }
      let request = GetTransactionRequest(hash: transaction.id)
      Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { [weak self] result in
        guard let `self` = self else { return }
        if let trans = self.storage.get(forPrimaryKey: transaction.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        switch result {
        case .success:
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
  }

  fileprivate func checkTransactionReceipt(_ transaction: Transaction, completion: @escaping (Error?) -> Void) {
    let request = KNGetTransactionReceiptRequest(hash: transaction.id)
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { [weak self] result in
      switch result {
      case .success(let receipt):
        if let trans = self?.storage.get(forPrimaryKey: transaction.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        let newTransaction = Transaction(
          id: transaction.id,
          blockNumber: Int(receipt.blockNumber) ?? transaction.blockNumber,
          from: transaction.from,
          to: transaction.to,
          value: transaction.value,
          gas: transaction.gas,
          gasPrice: transaction.gasPrice,
          gasUsed: receipt.gasUsed,
          nonce: transaction.nonce,
          date: transaction.date,
          localizedOperations: Array(transaction.localizedOperations),
          state: transaction.state
        )
        self?.storage.delete([transaction])
        self?.storage.add([newTransaction])
        if receipt.status == "1" {
          self?.storage.update(state: .completed, for: newTransaction)
          KNNotificationUtil.postNotification(for: KNPendingTxNotificationKeys.completed.rawValue, object: newTransaction, userInfo: nil)
        } else {
          self?.storage.update(state: .failed, for: newTransaction)
          KNNotificationUtil.postNotification(for: KNPendingTxNotificationKeys.failed.rawValue, object: newTransaction, userInfo: nil)
        }
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }

  func stopUpdatingPendingTransactions() {
    self.timer?.invalidate()
    self.timer = nil
  }
}
