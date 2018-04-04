// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNHistoryTransaction: Object {

  @objc dynamic var id: String = ""
  @objc dynamic var blockNumber: Int = 0
  @objc dynamic var date: Date = Date()
  @objc dynamic var from: String = ""
  @objc dynamic var to: String = ""
  // in case it is an exchange
  @objc dynamic var fromToken: String = ""
  @objc dynamic var toToken: String = ""
  @objc dynamic var value: String = ""
  // dest amount in case it is an exchange
  @objc dynamic var toValue: String = ""
  @objc dynamic var gasUsed: String = ""
  @objc dynamic var state: Int = TransactionState.unknown.rawValue

  convenience init(transaction: Transaction, wallet: Wallet) {
    self.init()
    let tokens = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
    self.id = transaction.id
    self.blockNumber = transaction.blockNumber
    self.date = transaction.date
    self.from = transaction.from.lowercased()
    if self.from != wallet.address.description.lowercased() {
      // receive tokens
      // TODO: Check which token received
      self.to = ""
      self.fromToken = ""
      self.toToken = ""
      self.value = transaction.value
    } else {
      // transfer or exchange
      if let netAddress = KNEnvironment.default.knCustomRPC?.networkAddress, netAddress == transaction.to.lowercased() {
        // An exchange, because the receiver is network address
        // either exchange from ETH to token or token to ETH, can check by using value
        //TODO: Get value, from/to tokens, rate
      } else {
        // a transfer, either transfer eth or a token
        if let token = tokens.first(where: { $0.address == transaction.to.lowercased() }) {
          // transfer token
          self.fromToken = token.address
          // TODO: Get receiver address + amount
        } else {
          self.fromToken = (tokens.first(where: { $0.isETH })?.address) ?? ""
          self.to = transaction.to.lowercased()
          self.value = transaction.value
        }
      }
    }
    self.gasUsed = transaction.gasUsed
    self.state = transaction.state.rawValue
  }

  override static func primaryKey() -> String? {
    return "id"
  }
}
