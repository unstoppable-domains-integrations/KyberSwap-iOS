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

  private(set) var keystore: Keystore
  private(set) var wallet: Wallet
  let web3Swift: Web3Swift
  let externalProvider: KNExternalProvider
  private(set) var realm: Realm
  private(set) var storage: TransactionsStorage

  fileprivate var transacionCoordinator: KNTransactionCoordinator?

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
    self.transacionCoordinator?.stopUpdatingPendingTransactions()
    self.transacionCoordinator = KNTransactionCoordinator(
      storage: self.storage,
      externalProvider: self.externalProvider,
      wallet: self.wallet
    )
    self.transacionCoordinator?.start()
  }

  func stopSession() {
    self.keystore.wallets.forEach { _ = self.keystore.delete(wallet: $0) }
    self.transacionCoordinator?.stopUpdatingPendingTransactions()
    self.transacionCoordinator = nil

    // Clear all data & tracker
    KNAppTracker.resetAppTrackerDidExitSession(self)
    self.storage.deleteAll()
    self.keystore.recentlyUsedWallet = nil
  }

  // Switch between wallets
  func switchSession(_ wallet: Wallet) {
    self.transacionCoordinator?.stopUpdatingPendingTransactions()
    self.transacionCoordinator = nil

    // Clear all data & tracker
    KNAppTracker.resetAppTrackerDidExitSession(self)

    self.wallet = wallet
    self.keystore.recentlyUsedWallet = wallet

    var account: Account!
    if case .real(let acc) = self.wallet.type {
      account = acc
    }
    self.externalProvider.updateNewAccount(account)
    let config = RealmConfiguration.configuration(for: wallet, chainID: KNEnvironment.default.chainID)
    self.realm = try! Realm(configuration: config)
    self.storage = TransactionsStorage(realm: self.realm)
  }

  func addNewPendingTransaction(_ transaction: Transaction) {
    // Put here to be able force update new pending transaction immmediately
    self.storage.add([transaction])
    self.transacionCoordinator?.updatePendingTranscation(transaction)
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
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

extension KNSession {
  var sessionID: String {
    return KNSession.sessionID(from: self.wallet)
  }

  static func sessionID(from wallet: Wallet) -> String {
    return KNSession.sessionID(from: wallet.address)
  }

  static func sessionID(from address: Address) -> String {
    return "sessionID-\(address.description)"
  }
}
