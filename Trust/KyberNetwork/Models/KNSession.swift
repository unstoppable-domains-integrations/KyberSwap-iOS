// Copyright SIX DAY LLC. All rights reserved.

import APIKit
import JSONRPCKit
import BigInt
import TrustKeystore

class KNSession {

  let keystore: Keystore
  let wallet: Wallet
  let web3Swift: Web3Swift
  let externalProvider: KNExternalProvider

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
  }

  func startSession() {
    self.web3Swift.start()
  }

  func stopSession() {
    _ = self.keystore.delete(wallet: self.wallet)
  }
}
