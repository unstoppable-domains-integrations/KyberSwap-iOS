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

  let transactionStorage: TransactionsStorage
  let tokenStorage: KNTokenStorage
  let externalProvider: KNExternalProvider
  let wallet: Wallet

  fileprivate var pendingTxTimer: Timer?
  fileprivate var allTxTimer: Timer?
  fileprivate var tokenTxTimer: Timer?

  deinit { self.stop() }

  init(
    transactionStorage: TransactionsStorage,
    tokenStorage: KNTokenStorage,
    externalProvider: KNExternalProvider,
    wallet: Wallet
    ) {
    self.transactionStorage = transactionStorage
    self.tokenStorage = tokenStorage
    self.externalProvider = externalProvider
    self.wallet = wallet
  }

  func start() {
    self.startUpdatingAllTransactions()
    self.startUpdatingListERC20TokenTransactions()
    self.startUpdatingPendingTransactions()
  }

  func stop() {
    self.stopUpdatingAllTransactions()
    self.stopUpdatingListERC20TokenTransactions()
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
        provider.getTokenBalance(for: Address(string: transaction.from.contract)!, completion: { result in
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

      let token: TokenObject = transaction.transferType.tokenObject()

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
        provider.getTokenBalance(for: Address(string: token.contract)!, completion: { result in
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
//        let startBlock: Int = {
//          guard let transaction = self.storage.completedObjects.first else { return 1 }
//          return transaction.blockNumber - 2000
//          return 1
//        }()
//        self.fetchTransaction(
//          for: self.wallet.address,
//          startBlock: startBlock,
//          completion: nil
//        )
        let fromDate: Date? = {
          guard let transaction = self.transactionStorage.historyTransactions.first else { return nil }
          return Date(timeIntervalSince1970: Double(transaction.blockTimestamp))
        }()
        self.fetchHistoryTransactions(
          from: fromDate,
          toDate: nil,
          address: self.wallet.address.description,
          completion: nil
        )
    })
  }

  func stopUpdatingAllTransactions() {
    self.allTxTimer?.invalidate()
    self.allTxTimer = nil
  }

//  func fetchTransaction(for address: Address, startBlock: Int, page: Int = 0, completion: ((Result<[Transaction], AnyError>) -> Void)?) {
//    NSLog("Fetch transactions from block \(startBlock) page \(page)")
//    let etherScanProvider = MoyaProvider<KNEtherScanService>()
//    etherScanProvider.request(.getListTransactions(address: address.description, startBlock: startBlock, endBlock: 99999999, page: 0)) { [weak self] result in
//      guard let `self` = self else { return }
//      switch result {
//      case .success(let response):
//        do {
//          let json: JSONDictionary = response.mapJSON(failsOnEmptyData: false))
//          let transArr: [JSONDictionary] = json["result"])
//          let rawTransactions: [RawTransaction] = try transArr.map({ try  RawTransaction.from(dictionary: $0) })
//          let transactions: [Transaction] = rawTransactions.flatMap({ return Transaction.from(transaction: $0) })
//          if !transactions.isEmpty {
//            self.storage.add(transactions)
//            self.updateHistoryTransactions(from: transactions)
//          }
//          NSLog("Successfully fetched \(transactions.count) transactions")
//          completion?(.success(transactions))
//        } catch let error {
//          NSLog("Fetching transactions parse failed with error: \(error.prettyError)")
//          completion?(.failure(AnyError(error)))
//        }
//      case .failure(let error):
//        NSLog("Fetching transactions failed with error: \(error.prettyError)")
//        completion?(.failure(AnyError(error)))
//      }
//    }
//  }

  func fetchHistoryTransactions(from fromDate: Date?, toDate: Date?, address: String, completion: ((Result<[KNHistoryTransaction], AnyError>) -> Void)?) {
    let trackerProvider = MoyaProvider<KNTrackerService>()
    trackerProvider.request(.getTrades(fromDate: fromDate, toDate: toDate, address: address)) { result in
      switch result {
      case .success(let response):
        do {
          let json: JSONDictionary = try response.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let transArr: [JSONDictionary] = json["data"] as? [JSONDictionary] ?? []
          let historyTransactions: [KNHistoryTransaction] = transArr.map({ return KNHistoryTransaction(dictionary: $0) })
          self.updateHistoryTransactions(historyTransactions)
          completion?(.success(historyTransactions))
        } catch let err {
          completion?(.failure(AnyError(err)))
        }
      case .failure(let error):
        completion?(.failure(AnyError(error)))
      }
    }
  }

  func updateHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    self.transactionStorage.addHistoryTransactions(transactions)
    KNNotificationUtil.postNotification(
      for: kTransactionListDidUpdateNotificationKey,
      object: transactions,
      userInfo: nil
    )
  }
}

// MARK: ERC20 Token transactions
extension KNTransactionCoordinator {
  func startUpdatingListERC20TokenTransactions() {
    self.tokenTxTimer?.invalidate()
    if KNAppTracker.transactionLoadState(for: self.wallet.address) != .done {
      self.initialFetchERC20TokenTransactions(
        forAddress: self.wallet.address,
        page: 1,
        completion: nil
      )
    }
    self.tokenTxTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
      self?.forceFetchTokenTransactions()
    })
  }

  func stopUpdatingListERC20TokenTransactions() {
    self.tokenTxTimer?.invalidate()
    self.tokenTxTimer = nil
  }

  func forceFetchTokenTransactions() {
    let startBlock: Int = {
      guard let transaction = self.transactionStorage.tokenTransactions.first else {
        return 0
      }
      return transaction.blockNumber + 1
    }()
    self.fetchListERC20TokenTransactions(
      forAddress: self.wallet.address.description,
      startBlock: startBlock,
      page: 1,
      sort: "asc",
      completion: nil
    )
  }

  func fetchListERC20TokenTransactions(
    forAddress address: String,
    startBlock: Int,
    page: Int,
    sort: String,
    completion: ((Result<[KNTokenTransaction], AnyError>) -> Void)?
    ) {
    print("---- ERC20 Token Transactions: Fetching ----")
    let provider = MoyaProvider<KNEtherScanService>()
    let service = KNEtherScanService.getListTokenTransactions(
      address: address,
      startBlock: startBlock,
      page: page,
      sort: sort
    )
    provider.request(service) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let response):
        do {
          let json: JSONDictionary = try response.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let data: [JSONDictionary] = json["result"] as? [JSONDictionary] ?? []
          let transactions = data.map({ return KNTokenTransaction(dictionary: $0) })
          self.updateListTokenTransactions(transactions)
          print("---- ERC20 Token Transactions: Loaded \(transactions.count) transactions ----")
          completion?(.success(transactions))
        } catch let error {
          print("---- ERC20 Token Transactions: Parse result failed with error: \(error.prettyError) ----")
          completion?(.failure(AnyError(error)))
        }
      case .failure(let error):
        print("---- ERC20 Token Transactions: Failed with error: \(error.errorDescription ?? "") ----")
        completion?(.failure(AnyError(error)))
      }
    }
  }

  func initialFetchERC20TokenTransactions(forAddress address: Address, page: Int = 1, completion: ((Result<[KNTokenTransaction], AnyError>) -> Void)?) {
    self.fetchListERC20TokenTransactions(
      forAddress: address.description,
      startBlock: 1,
      page: page,
      sort: "desc") { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let transactions):
        if transactions.isEmpty || self.transactionStorage.tokenTransactions.count >= 5000 {
          // done loading or too many transactions
          KNAppTracker.updateTransactionLoadState(.done, for: address)
        } else {
          DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25, execute: {
            self.initialFetchERC20TokenTransactions(
              forAddress: address,
              page: page + 1,
              completion: nil
            )
          })
        }
        completion?(.success(transactions))
      case .failure(let error):
        KNAppTracker.updateTransactionLoadState(.failed, for: address)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0, execute: {
          self.initialFetchERC20TokenTransactions(
            forAddress: address,
            page: page + 1,
            completion: nil
          )
        })
        completion?(.failure(AnyError(error)))
      }
    }
  }

  func updateListTokenTransactions(_ transactions: [KNTokenTransaction]) {
    self.transactionStorage.add(transactions: transactions)
    KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
    var tokenObjects: [TokenObject] = []
    transactions.forEach { tx in
      if let token = tx.getToken(), !tokenObjects.contains(token), !self.tokenStorage.tokens.contains(token) { tokenObjects.append(token) }
    }
    if !tokenObjects.isEmpty {
      self.tokenStorage.add(tokens: tokenObjects)
      KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
    }
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
    self.transactionStorage.pendingObjects.forEach { self.updatePendingTranscation($0) }
  }

  func updatePendingTranscation(_ transaction: Transaction) {
    self.checkTransactionReceipt(transaction) { [weak self] error in
      if error == nil { return }
      guard let `self` = self else { return }
      self.externalProvider.getTransactionByHash(transaction.id, completion: { [weak self] sessionError in
        guard let `self` = self else { return }
        if let trans = self.transactionStorage.get(forPrimaryKey: transaction.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        if let error = sessionError {
          // Failure
          if case .responseError(let err) = error, let respError = err as? JSONRPCError {
            switch respError {
            case .responseError(let code, let message, _):
              NSLog("Fetch pending transaction with hash \(transaction.id) failed with error code \(code) and message \(message)")
              self.transactionStorage.delete([transaction])
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
        if let trans = self?.transactionStorage.get(forPrimaryKey: newTx.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        self?.transactionStorage.add([newTx])
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
    if let trans = self.transactionStorage.get(forPrimaryKey: transaction.id), trans.state != .pending { return }
    self.transactionStorage.update(state: state, for: transaction)
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
    let token: TokenObject = self.transferType.tokenObject()

    let localObject = LocalizedOperationObject(
      from: token.contract,
      to: "",
      contract: nil,
      type: "transfer",
      value: self.value.fullString(decimals: token.decimals),
      symbol: nil,
      name: nil,
      decimals: token.decimals
    )
    return Transaction(
      id: hash,
      blockNumber: 0,
      from: wallet.address.description,
      to: self.to?.description ?? "",
      value: self.value.fullString(decimals: token.decimals),
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
  static func from(dictionary: JSONDictionary) -> RawTransaction {
    let id: String = dictionary["hash"] as? String ?? ""
    let blockNumber = Int(dictionary["blockNumber"] as? String ?? "0") ?? 0
    let from: String = dictionary["from"] as? String ?? ""
    let to: String = dictionary["to"] as? String ?? ""
    let value: String = dictionary["value"] as? String ?? ""
    let gas: String = dictionary["gas"] as? String ?? ""
    let gasPrice: String = dictionary["gasPrice"] as? String ?? ""
    let gasUsed: String = dictionary["gasUsed"] as? String ?? ""
    let nonce: Int = Int(dictionary["nonce"] as? String ?? "0") ?? 0
    let timeStamp: String = dictionary["timeStamp"] as? String ?? ""
    let input: String = dictionary["input"] as? String ?? ""
    let isError: String? = dictionary["isError"] as? String

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

// MARK: Transaction Storage Extension
extension TransactionsStorage {
  func addHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    self.realm.beginWrite()
    self.realm.add(transactions, update: true)
    try! realm.commitWrite()
  }

  func deleteHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    try! self.realm.write {
      self.realm.delete(transactions)
    }
  }

  func deleteAllHistoryTransactions() {
    try! self.realm.write {
      self.realm.delete(self.realm.objects(KNHistoryTransaction.self))
    }
  }

  var historyTransactions: [KNHistoryTransaction] {
    return self.realm.objects(KNHistoryTransaction.self)
      .sorted(byKeyPath: "blockTimestamp", ascending: false)
      .filter { !$0.id.isEmpty }
  }
}
