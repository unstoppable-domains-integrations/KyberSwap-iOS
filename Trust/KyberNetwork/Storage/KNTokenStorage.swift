// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import BigInt

class KNTokenStorage {

  private(set) var realm: Realm
  private let supportedTokens: [KNToken] = KNJSONLoaderUtil.shared.tokens

  init(realm: Realm) {
    self.realm = realm
    self.addKyberSupportedTokens()
  }

  private func addKyberSupportedTokens() {
    let supportedTokeObjects = self.supportedTokens.map({ return $0.toTokenObject() })
    // update balance
    supportedTokeObjects.forEach { tokenObject in
      if let token = self.tokens.first(where: { $0.contract == tokenObject.contract }) {
        tokenObject.value = token.value
      }
    }
    self.add(tokens: supportedTokeObjects)
  }

  var tokens: [TokenObject] {
    return self.realm.objects(TokenObject.self)
      .sorted(byKeyPath: "contract", ascending: true)
      .filter { !$0.contract.isEmpty }
  }

  var ethToken: TokenObject {
    let eth = self.supportedTokens.first(where: { $0.isETH })!
    return self.tokens.first(where: { $0.contract == eth.address })!
  }

  var kncToken: TokenObject {
    let knc = self.supportedTokens.first(where: { $0.isKNC })!
    return self.tokens.first(where: { $0.contract == knc.address })!
  }

  static func iconImageName(for token: TokenObject) -> String {
    let localTokens = KNJSONLoaderUtil.shared.tokens
    return localTokens.first(where: { $0.address == token.contract })?.icon ?? ""
  }

  func get(forPrimaryKey key: String) -> TokenObject? {
    return self.realm.object(ofType: TokenObject.self, forPrimaryKey: key)
  }

  func addCustom(token: ERC20Token) {
    let newToken = TokenObject(
      contract: token.contract.description.lowercased(),
      name: token.name,
      symbol: token.symbol.uppercased(),
      decimals: token.decimals,
      value: "0",
      isCustom: true
    )
    add(tokens: [newToken])
  }

  func add(tokens: [TokenObject]) {
    self.realm.beginWrite()
    self.realm.add(tokens, update: true)
    try!self.realm.commitWrite()
  }

  func updateBalance(for token: TokenObject, balance: BigInt) {
    try! self.realm.write {
      token.value = balance.description
    }
  }

  func delete(tokens: [TokenObject]) {
    realm.beginWrite()
    realm.delete(tokens)
    try! realm.commitWrite()
  }

  func deleteAll() {
    try! realm.write {
      realm.delete(realm.objects(TokenObject.self))
    }
  }
}
