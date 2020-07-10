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
    let supportedTokenObjects = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
    supportedTokenObjects.forEach { token in
      if let savedToken = self.supportedTokens.first(where: { $0.contract == token.contract }) {
        token.value = savedToken.value
      }
    }
    self.add(tokens: supportedTokenObjects)
  }

  var supportedTokens: [TokenObject] {
    if self.realm.objects(TokenObject.self).isInvalidated { return [] }
    return self.realm.objects(TokenObject.self)
      .filter { return !$0.contract.isEmpty }
  }

  var ethToken: TokenObject {
    return self.supportedTokens.first(where: { return $0.isETH })!.clone()
  }

  var wethToken: TokenObject? {
    return self.supportedTokens.first(where: { return $0.isWETH })?.clone()
  }

  var kncToken: TokenObject {
    return self.supportedTokens.first(where: { $0.isKNC })!.clone()
  }

  var ptToken: TokenObject? {
    return self.supportedTokens.first(where: { $0.isPromoToken })?.clone()
  }

  func get(forPrimaryKey key: String) -> TokenObject? {
    return self.realm.object(ofType: TokenObject.self, forPrimaryKey: key)
  }

  /**
   Update supported token list if needed
   */
  func updateSupportedTokens(tokenObjects: [TokenObject]) {
    if self.realm.objects(TokenObject.self).isInvalidated { return }
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
    let removedTokens = savedTokens.filter { token -> Bool in
      return tokenObjects.first(where: { $0.contract == token.contract }) == nil
    }
    self.delete(tokens: removedTokens)
    // Send post notification to update other UI if needed
    KNNotificationUtil.postNotification(for: kSupportedTokenListDidUpdateNotificationKey)
  }

  func add(tokens: [TokenObject]) {
    if self.realm.objects(TokenObject.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.add(tokens, update: .modified)
    try! self.realm.commitWrite()
  }

  func delete(tokens: [TokenObject]) {
    if self.realm.objects(TokenObject.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(tokens)
    try! realm.commitWrite()
  }

  func deleteAll() {
    if self.realm.objects(TokenObject.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(realm.objects(TokenObject.self))
    try! self.realm.commitWrite()
  }
}
