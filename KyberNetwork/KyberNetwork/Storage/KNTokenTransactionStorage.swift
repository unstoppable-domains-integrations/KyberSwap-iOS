// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

extension TransactionsStorage {

  var tokenTransactions: [KNTokenTransaction] {
    if self.realm.objects(KNTokenTransaction.self).isInvalidated { return [] }
    let data: [KNTokenTransaction] = self.realm.objects(KNTokenTransaction.self)
      .sorted(by: { return $0.date < $1.date || ($0.date == $1.date && $0.id < $1.id ) })
    return data.filter({ return !$0.id.isEmpty })
  }

  func add(transactions: [KNTokenTransaction]) {
    if realm.objects(KNTokenTransaction.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.add(transactions, update: .modified)
    try! self.realm.commitWrite()
  }

  func delete(transactions: [KNTokenTransaction]) {
    if realm.objects(KNTokenTransaction.self).isInvalidated { return }
    realm.beginWrite()
    realm.delete(transactions)
    try! realm.commitWrite()
  }

  func deleteAllTokenTransactions() {
    if realm.objects(KNTokenTransaction.self).isInvalidated { return }
    try! realm.write {
      realm.delete(realm.objects(KNTokenTransaction.self))
    }
  }
}
