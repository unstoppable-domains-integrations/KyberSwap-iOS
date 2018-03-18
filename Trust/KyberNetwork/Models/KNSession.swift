// Copyright SIX DAY LLC. All rights reserved.

import APIKit
import JSONRPCKit
import BigInt
import TrustKeystore
import RealmSwift

protocol KNSessionDelegate: class {
  func userDidClickExitSession()
}

class KNSession {

  let keystore: Keystore
  let wallet: Wallet
  let web3Swift: Web3Swift
  let externalProvider: KNExternalProvider
  let realm: Realm
  let storage: TransactionsStorage

  fileprivate var pendingTxCoordinator: KNPendingTransactionCoordinator?

  init(keystore: Keystore,
       wallet: Wallet) {
    self.keystore = keystore
    self.wallet = wallet
    if let customRPC = KNEnvironment.default.customRPC, let path = URL(string: customRPC.endpoint) {
      self.web3Swift = Web3Swift(url: path)
    } else {
      self.web3Swift = Web3Swift()
    }
    // Wallet type should always be real(account)
    var account: Account!
    if case .real(let acc) = self.wallet.type {
      account = acc
    }
    self.externalProvider = KNExternalProvider(web3: self.web3Swift, keystore: self.keystore, account: account)
    let config = RealmConfiguration.configuration(for: wallet, chainID: KNEnvironment.default.chainID)
    self.realm = try! Realm(configuration: config)
    self.storage = TransactionsStorage(realm: self.realm)
  }

  func startSession() {
    self.web3Swift.start()
    self.pendingTxCoordinator?.stopUpdatingPendingTransactions()
    self.pendingTxCoordinator = KNPendingTransactionCoordinator(storage: self.storage)
    self.pendingTxCoordinator?.startUpdatingPendingTransactions()
  }

  func stopSession() {
    _ = self.keystore.delete(wallet: self.wallet)
    self.pendingTxCoordinator?.stopUpdatingPendingTransactions()
    self.pendingTxCoordinator = nil
  }

  func addNewPendingTransaction(_ transaction: Transaction) {
    // Put here to be able force update new pending transaction immmediately
    self.storage.add([transaction])
    self.pendingTxCoordinator?.updatePendingTranscation(transaction)
    KNNotificationUtil.postNotification(
      for: KNPendingTransactionCoordinator.didUpdateNotificationKey,
      object: transaction.id,
      userInfo: nil
    )
  }

  static func resumeInternalSession() {
    KNRateCoordinator.shared.resume()
    KNGasCoordinator.shared.resume()
    KNRecentTradeCoordinator.shared.resume()
  }

  static func pauseInternalSession() {
    KNRateCoordinator.shared.pause()
    KNGasCoordinator.shared.pause()
    KNRecentTradeCoordinator.shared.pause()
  }
}
