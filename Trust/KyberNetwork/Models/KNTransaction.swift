// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import RealmSwift

enum KNTransactionType {
  case transfer(UnconfirmedTransaction)
  case exchange(KNDraftExchangeTransaction)
  case buyTokenSale(IEODraftTransaction)

  var isTransfer: Bool {
    if case .transfer = self { return true }
    return false
  }
}

class KNTransaction: Object {
  @objc dynamic var id: String = ""
  @objc dynamic var blockNumber: Int = 0
  @objc dynamic var from = ""
  @objc dynamic var to = ""
  @objc dynamic var value = ""
  @objc dynamic var gas = ""
  @objc dynamic var gasPrice = ""
  @objc dynamic var gasUsed = ""
  @objc dynamic var nonce: String = ""
  @objc dynamic var date = Date()
  @objc dynamic var internalState: Int = TransactionState.completed.rawValue
  var localizedOperations = List<LocalizedOperationObject>()

  convenience init(
    id: String,
    blockNumber: Int,
    from: String,
    to: String,
    value: String,
    gas: String,
    gasPrice: String,
    gasUsed: String,
    nonce: String,
    date: Date,
    localizedOperations: [LocalizedOperationObject],
    state: TransactionState
    ) {

    self.init()
    self.id = id
    self.blockNumber = blockNumber
    self.from = from
    self.to = to
    self.value = value
    self.gas = gas
    self.gasPrice = gasPrice
    self.gasUsed = gasUsed
    self.nonce = nonce
    self.date = date
    self.internalState = state.rawValue

    let list = List<LocalizedOperationObject>()
    localizedOperations.forEach { element in
      list.append(element)
    }

    self.localizedOperations = list
  }

  override static func primaryKey() -> String? {
    return "id"
  }

  var state: TransactionState {
    return TransactionState(int: self.internalState)
  }
}

extension KNTransaction {
  var operation: LocalizedOperationObject? {
    return localizedOperations.first
  }

  var shortDesc: String {
    guard let object = self.localizedOperations.first else { return "" }
    if object.type == "transfer" {
      return "\(object.symbol ?? "") -> \(self.to.prefix(10))..."
    }
    return "\(object.symbol ?? "") -> \(object.name ?? "")"
  }

  var isTransfer: Bool {
    guard let object = self.localizedOperations.first else { return false }
    return object.type == "transfer"
  }
}

extension KNTransaction {
  func getTokenObject() -> TokenObject? {
    guard let localObject = self.localizedOperations.first, localObject.type == "transfer" else {
      return nil
    }
    return TokenObject(
      contract: localObject.contract ?? "",
      name: localObject.name ?? "",
      symbol: localObject.symbol ?? "",
      decimals: localObject.decimals,
      value: "0",
      isCustom: false,
      isDisabled: false
    )
  }

  static func from(transaction: Transaction) -> KNTransaction {
    var operations: [LocalizedOperationObject] = []
    for object in transaction.localizedOperations {
      operations.append(object)
    }
    return KNTransaction(
      id: transaction.id,
      blockNumber: transaction.blockNumber,
      from: transaction.from,
      to: transaction.to,
      value: transaction.value,
      gas: transaction.gas,
      gasPrice: transaction.gasPrice,
      gasUsed: transaction.gasUsed,
      nonce: transaction.nonce,
      date: transaction.date,
      localizedOperations: operations,
      state: transaction.state
    )
  }

  func toTransaction() -> Transaction {
    var operations: [LocalizedOperationObject] = []
    for object in self.localizedOperations {
      operations.append(object)
    }
    return Transaction(
      id: self.id,
      blockNumber: self.blockNumber,
      from: self.from,
      to: self.to,
      value: self.value,
      gas: self.gas,
      gasPrice: self.gasPrice,
      gasUsed: self.gasUsed,
      nonce: self.nonce,
      date: self.date,
      localizedOperations: operations,
      state: self.state
    )
  }
}

extension TransactionsStorage {
  var kyberTransactions: [KNTransaction] {
    return realm.objects(KNTransaction.self)
      .sorted(byKeyPath: "date", ascending: false)
      .filter { !$0.id.isEmpty }
  }

  var kyberPendingTransactions: [KNTransaction] {
    return self.kyberTransactions.filter { $0.state == TransactionState.pending }
  }

  func getKyberTransaction(forPrimaryKey: String) -> KNTransaction? {
    return realm.object(ofType: KNTransaction.self, forPrimaryKey: forPrimaryKey)
  }

  @discardableResult
  func addKyberTransactions(_ items: [KNTransaction]) -> [KNTransaction] {
    realm.beginWrite()
    realm.add(items, update: true)
    try! realm.commitWrite()
    return items
  }

  func delete(_ items: [KNTransaction]) {
    try! realm.write {
      realm.delete(items)
    }
  }

  @discardableResult
  func update(state: TransactionState, for transaction: KNTransaction) -> KNTransaction {
    realm.beginWrite()
    transaction.internalState = state.rawValue
    try! realm.commitWrite()
    return transaction
  }

  func deleteAllKyberTransactions() {
    self.delete(self.kyberTransactions)
  }
}
