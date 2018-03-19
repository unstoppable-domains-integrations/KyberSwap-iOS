// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import APIKit
import JSONRPCKit
import JavaScriptKit
import Result
import BigInt

class KNPendingTransactionCoordinator {

  static let didUpdateNotificationKey = "KNPendingTransactionCoordinatorNotificationKey"

  let storage: TransactionsStorage
  let web3Swift: Web3Swift
  fileprivate var timer: Timer?

  init(storage: TransactionsStorage, web3Swift: Web3Swift) {
    self.storage = storage
    self.web3Swift = web3Swift
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
            KNNotificationUtil.postNotification(
              for: KNPendingTransactionCoordinator.didUpdateNotificationKey,
              object: transaction.id,
              userInfo: nil
            )
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
                KNNotificationUtil.postNotification(
                  for: KNPendingTransactionCoordinator.didUpdateNotificationKey,
                  object: transaction.id,
                  userInfo: nil
                )
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
      guard let `self` = self else { return }
      switch result {
      case .success(let receipt):
        if let trans = self.storage.get(forPrimaryKey: transaction.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        let web3Decode = KNExchangeEvenDataDecode(data: receipt.logsData)
        self.web3Swift.request(request: web3Decode, completion: { [weak self] decodeResult in
          let localObjects: [LocalizedOperationObject] = {
            let dict: JSONDictionary? = {
              switch decodeResult {
              case .success(let dict):
                return dict
              case .failure(let error):
                if let err = error.error as? JSErrorDomain {
                  if case .invalidReturnType(let object) = err, let json = object as? JSONDictionary {
                    return json
                  }
                }
              }
              return nil
            }()
            guard let json = dict else { return Array(transaction.localizedOperations) }
            let valueString: String = {
              let value = BigInt(json["destAmount"] as? String ?? "") ?? BigInt(0)
              if let token = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.address == (json["dest"] as? String ?? "").lowercased() }) {
                return value.fullString(decimals: token.decimal)
              }
              return value.fullString(units: .ether)
            }()
            let localObject = LocalizedOperationObject(
              from: (json["src"] as? String ?? "").lowercased(),
              to: (json["dest"] as? String ?? "").lowercased(),
              contract: nil,
              type: "exchange",
              value: valueString,
              symbol: nil,
              name: nil,
              decimals: 18
            )
            return [localObject]
          }()
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
            localizedOperations: localObjects,
            state: transaction.state
          )
          self?.storage.add([newTransaction])
          self?.storage.update(state: receipt.status == "1" ? .completed : .failed, for: newTransaction)
          KNNotificationUtil.postNotification(
            for: KNPendingTransactionCoordinator.didUpdateNotificationKey,
            object: newTransaction.id,
            userInfo: nil
          )
          completion(nil)
        })
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
