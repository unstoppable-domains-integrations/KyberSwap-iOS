// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

extension TransactionsStorage {

  var tokenTransactions: [KNTokenTransaction] {
    return self.realm.objects(KNTokenTransaction.self)
      .sorted(byKeyPath: "date", ascending: false)
      .filter { !$0.id.isEmpty }
  }

  func add(transactions: [KNTokenTransaction]) {
    self.realm.beginWrite()
    self.realm.add(transactions, update: true)
    try!self.realm.commitWrite()
  }

  func delete(transactions: [KNTokenTransaction]) {
    realm.beginWrite()
    realm.delete(transactions)
    try! realm.commitWrite()
  }

  func deleteAllTokenTransactions() {
    try! realm.write {
      realm.delete(realm.objects(KNTokenTransaction.self))
    }
  }
}
