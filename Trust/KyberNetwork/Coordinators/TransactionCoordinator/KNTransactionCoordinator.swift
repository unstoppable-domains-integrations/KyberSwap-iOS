// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import APIKit
import JSONRPCKit
import JavaScriptKit
import Result
import BigInt
import TrustKeystore
import Moya

class KNTransactionCoordinator {

  let storage: TransactionsStorage
  let externalProvider: KNExternalProvider
  let wallet: Wallet

  fileprivate var pendingTxTimer: Timer?
  fileprivate var allTxTimer: Timer?

  deinit { self.stop() }

  init(storage: TransactionsStorage, externalProvider: KNExternalProvider, wallet: Wallet) {
    self.storage = storage
    self.externalProvider = externalProvider
    self.wallet = wallet
  }

  func start() {
    self.startUpdatingAllTransactions()
    self.startUpdatingPendingTransactions()
  }

  func stop() {
    self.stopUpdatingAllTransactions()
    self.stopUpdatingPendingTransactions()
  }
}

// MARK: Lock data when user confirmed
extension KNTransactionCoordinator {

  // Prepare data before submitting exchange request
  // Data needed: gas limit, expected rate
  static func requestDataPrepareForExchangeTransaction(_ transaction: KNDraftExchangeTransaction, provider: KNExternalProvider, completion: @escaping (Result<KNDraftExchangeTransaction?, AnyError>) -> Void) {
    DispatchQueue.global().async {
      var error: AnyError?
      let group = DispatchGroup()

      // Est Gas Used
      var gasLimit = transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
      group.enter()
      provider.getEstimateGasLimit(for: transaction) { result in
        switch result {
        case .success(let gas): gasLimit = gas
        // TODO (Mike): Est. Gas Limit is temp not working
        //case .failure(let err): error = err
        default: break
        }
        group.leave()
      }

      // Expected Rate
      var expectedRate = transaction.expectedRate
      group.enter()
      provider.getExpectedRate(
        from: transaction.from,
        to: transaction.to,
        amount: transaction.amount) { result in
          switch result {
          case .success(let data): expectedRate = data.0
          case .failure(let err): error = err
          }
          group.leave()
      }

      // Balance
      var balance = BigInt(0)
      group.enter()
      if transaction.from.isETH {
        provider.getETHBalance(completion: { result in
          switch result {
          case .success(let bal): balance = bal.value
          case .failure(let err): error = err
          }
          group.leave()
        })
      } else {
        provider.getTokenBalance(for: Address(string: transaction.from.address)!, completion: { result in
          switch result {
          case .success(let bal): balance = bal
          case .failure(let err): error = err
          }
          group.leave()
        })
      }

      group.notify(queue: .main) {
        if let err = error {
          completion(.failure(err))
          return
        }
        if balance < transaction.amount {
          completion(.success(nil))
          return
        }
        completion(.success(transaction.copy(expectedRate: expectedRate, gasLimit: gasLimit)))
      }
    }
  }

  // Prepare data before submitting transfer request
  // Data needed: gas limit
  static func requestDataPrepareForTransferTransaction(_ transaction: UnconfirmedTransaction, provider: KNExternalProvider, completion: @escaping (Result<UnconfirmedTransaction?, AnyError>) -> Void) {
    DispatchQueue.global().async {
      var error: AnyError?
      let group = DispatchGroup()

      let token: KNToken = transaction.transferType.knToken()

      // Est Gas Used
      var gasLimit: BigInt = {
        if let gas = transaction.gasLimit { return gas }
        return token.isETH ? KNGasConfiguration.transferETHGasLimitDefault : KNGasConfiguration.transferTokenGasLimitDefault
      }()
      group.enter()
      provider.getEstimateGasLimit(for: transaction) { result in
        switch result {
        case .success(let gas): gasLimit = gas
          // TODO (Mike): Est. Gas Limit is temp not working
        //case .failure(let err): error = err
        default: break
        }
        group.leave()
      }

      // Balance
      var balance = BigInt(0)
      group.enter()
      if token.isETH {
        provider.getETHBalance(completion: { result in
          switch result {
          case .success(let bal): balance = bal.value
          case .failure(let err): error = err
          }
          group.leave()
        })
      } else {
        provider.getTokenBalance(for: Address(string: token.address)!, completion: { result in
          switch result {
          case .success(let bal): balance = bal
          case .failure(let err): error = err
          }
          group.leave()
        })
      }

      group.notify(queue: .main) {
        if let err = error {
          completion(.failure(err))
          return
        }
        if balance < transaction.value {
          completion(.success(nil))
          return
        }
        let newTransaction = UnconfirmedTransaction(
          transferType: transaction.transferType,
          value: transaction.value,
          to: transaction.to,
          data: transaction.data,
          gasLimit: gasLimit,
          gasPrice: transaction.gasPrice,
          nonce: transaction.nonce
        )
        completion(.success(newTransaction))
      }
    }
  }
}

// MARK: Update transactions
extension KNTransactionCoordinator {
  func startUpdatingAllTransactions() {
    self.stopUpdatingAllTransactions()
    self.allTxTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        let startBlock: Int = {
          guard let transaction = self.storage.completedObjects.first else { return 1 }
          return transaction.blockNumber - 2000
        }()
        self.fetchTransaction(
          for: self.wallet.address,
          startBlock: startBlock,
          completion: nil
        )
    })
  }

  func stopUpdatingAllTransactions() {
    self.allTxTimer?.invalidate()
    self.allTxTimer = nil
  }

  func fetchTransaction(for address: Address, startBlock: Int, page: Int = 0, completion: ((Result<[Transaction], AnyError>) -> Void)?) {
    NSLog("Fetch transactions from block \(startBlock) page \(page)")
    let etherScanProvider = MoyaProvider<KNEtherScanService>()
    etherScanProvider.request(.getListTransactions(address: address.description, startBlock: startBlock, endBlock: 99999999, page: 0)) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let response):
        do {
          let json: JSONDictionary = try kn_cast(response.mapJSON(failsOnEmptyData: false))
          let transArr: [JSONDictionary] = try kn_cast(json["result"])
          let rawTransactions: [RawTransaction] = try transArr.map({ try  RawTransaction.from(dictionary: $0) })
          let transactions: [Transaction] = rawTransactions.flatMap({ return Transaction.from(transaction: $0) })
          if !transactions.isEmpty {
            self.storage.add(transactions)
            self.updateHistoryTransactions(from: transactions)
          }
          NSLog("Successfully fetched \(transactions.count) transactions")
          completion?(.success(transactions))
        } catch let error {
          NSLog("Fetching transactions parse failed with error: \(error.prettyError)")
          completion?(.failure(AnyError(error)))
        }
      case .failure(let error):
        NSLog("Fetching transactions failed with error: \(error.prettyError)")
        completion?(.failure(AnyError(error)))
      }
    }
  }

  func updateHistoryTransactions(from transactions: [Transaction]) {
    let historyTransactions = transactions.map({
      return KNHistoryTransaction(transaction: $0, wallet: self.wallet)
    })
    self.storage.addHistoryTransactions(historyTransactions)
    KNNotificationUtil.postNotification(
      for: kTransactionListDidUpdateNotificationKey,
      object: transactions,
      userInfo: nil
    )
  }
}

// MARK: Pending transactions
extension KNTransactionCoordinator {
  func startUpdatingPendingTransactions() {
    self.pendingTxTimer?.invalidate()
    self.pendingTxTimer = nil
    self.shouldUpdatePendingTransaction(nil)
    self.pendingTxTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
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
      for: kTransactionDidUpdateNotificationKey,
      object: transaction.id,
      userInfo: nil
    )
  }

  func stopUpdatingPendingTransactions() {
    self.pendingTxTimer?.invalidate()
    self.pendingTxTimer = nil
  }
}

extension UnconfirmedTransaction {
  func toTransaction(wallet: Wallet, hash: String, nounce: Int) -> Transaction {
    let token: KNToken = self.transferType.knToken()

    let localObject = LocalizedOperationObject(
      from: token.address,
      to: "",
      contract: nil,
      type: "transfer",
      value: self.value.fullString(decimals: token.decimal),
      symbol: nil,
      name: nil,
      decimals: token.decimal
    )
    return Transaction(
      id: hash,
      blockNumber: 0,
      from: wallet.address.description,
      to: self.to?.description ?? "",
      value: self.value.fullString(decimals: token.decimal),
      gas: self.gasLimit?.fullString(units: UnitConfiguration.gasFeeUnit) ?? "",
      gasPrice: self.gasPrice?.fullString(units: UnitConfiguration.gasPriceUnit) ?? "",
      gasUsed: self.gasLimit?.fullString(units: UnitConfiguration.gasFeeUnit) ?? "",
      nonce: "\(nounce)",
      date: Date(),
      localizedOperations: [localObject],
      state: .pending
    )
  }
}

extension RawTransaction {
  static func from(dictionary: JSONDictionary) throws -> RawTransaction {
    let id: String = try kn_cast(dictionary["hash"])
    let blockNumber = Int(dictionary["blockNumber"] as? String ?? "0") ?? 0
    let from: String = try kn_cast(dictionary["from"])
    let to: String = try kn_cast(dictionary["to"])
    let value: String = try kn_cast(dictionary["value"])
    let gas: String = try kn_cast(dictionary["gas"])
    let gasPrice: String = try kn_cast(dictionary["gasPrice"])
    let gasUsed: String = try kn_cast(dictionary["gasUsed"])
    let nonce: Int = Int(dictionary["nonce"] as? String ?? "0") ?? 0
    let timeStamp: String = try kn_cast(dictionary["timeStamp"])
    let input: String = try kn_cast(dictionary["input"])
    let isError: String? = try kn_cast(dictionary["isError"])

    return RawTransaction(
      hash: id,
      blockNumber: blockNumber,
      timeStamp: timeStamp,
      nonce: nonce,
      from: from,
      to: to,
      value: value,
      gas: gas,
      gasPrice: gasPrice,
      input: input,
      gasUsed: gasUsed,
      error: isError == "0" ? nil : isError,
      operations: nil
    )
  }
}

extension TransactionsStorage {
  func addHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    self.realm.beginWrite()
    self.realm.add(transactions, update: true)
    try! realm.commitWrite()
  }

  var historyTransactions: [KNHistoryTransaction] {
    return self.realm.objects(KNHistoryTransaction.self)
      .sorted(byKeyPath: "date", ascending: false)
      .filter { !$0.id.isEmpty }
  }
}
