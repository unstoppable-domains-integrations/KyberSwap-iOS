// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNSupportedTokenStorage {
  static let shared = KNSupportedTokenStorage()
  lazy var realm: Realm = {
    let config = RealmConfiguration.globalConfiguration()
    return try! Realm(configuration: config)
  }()

  func addLocalSupportedTokens() {
    let supportedTokenObjects = KNJSONLoaderUtil.shared.tokens
    supportedTokenObjects.forEach { token in
      if let savedToken = self.supportedTokens.first(where: { $0.contract == token.contract }) {
        token.value = savedToken.value
      }
    }
    self.add(tokens: supportedTokenObjects)
  }

  var supportedTokens: [TokenObject] {
    return self.realm.objects(TokenObject.self)
      .sorted(byKeyPath: "contract", ascending: true)
      .filter { !$0.contract.isEmpty }
  }

  var ethToken: TokenObject {
    return self.supportedTokens.first(where: { return $0.isETH })!
  }

  var kncToken: TokenObject {
    return self.supportedTokens.first(where: { $0.isKNC })!
  }

  func get(forPrimaryKey key: String) -> TokenObject? {
    return self.realm.object(ofType: TokenObject.self, forPrimaryKey: key)
  }

  /**
   Update supported token list if needed
   */
  func updateFromTracker(tokenObjects: [TokenObject]) {
    let savedTokens = self.supportedTokens
    let needUpdate: Bool = {
      if savedTokens.count != tokenObjects.count { return true }
      for id in 0..<savedTokens.count where savedTokens[id].contract != tokenObjects[id].contract { return true }
      return false
    }()
    if !needUpdate { return }
    tokenObjects.forEach { token in
      if let savedToken = savedTokens.first(where: { $0.contract == token.contract }) {
        token.value = savedToken.value
      }
    }
    self.add(tokens: tokenObjects)
    // Send post notification to update other UI if needed
    KNNotificationUtil.postNotification(for: kSupportedTokenListDidUpdateNotificationKey)
  }

  func add(tokens: [TokenObject]) {
    self.realm.beginWrite()
    self.realm.add(tokens, update: true)
    try! self.realm.commitWrite()
  }

  func delete(tokens: [TokenObject]) {
    self.realm.beginWrite()
    self.realm.delete(tokens)
    try! realm.commitWrite()
  }

  func deleteAll() {
    try! self.realm.write { realm.delete(realm.objects(TokenObject.self)) }
  }
}
