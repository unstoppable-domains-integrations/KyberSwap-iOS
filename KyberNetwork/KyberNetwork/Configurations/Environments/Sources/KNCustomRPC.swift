// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNCustomRPC {

  let customRPC: CustomRPC
  let networkAddress: String
  let authorizedAddress: String
  let tokenIEOAddress: String
  let reserveAddress: String
  let etherScanEndpoint: String
  let tradeTopic: String

  init(dictionary: JSONDictionary) {
    let chainID: Int = dictionary["networkId"] as? Int ?? 0
    let name: String = dictionary["chainName"] as? String ?? ""
    let symbol = name
    var endpoint: String
    if let connections: JSONDictionary = dictionary["connections"] as? JSONDictionary,
      let https: [JSONDictionary] = connections["http"] as? [JSONDictionary] {
      let endpointJSON: JSONDictionary = https.count > 1 ? https[1] : https[0]
      endpoint = endpointJSON["endPoint"] as? String ?? ""
    } else {
      endpoint = dictionary["endpoint"] as? String ?? ""
    }
    self.networkAddress = dictionary["network"] as? String ?? ""
    self.authorizedAddress = dictionary["authorize_contract"] as? String ?? ""
    self.tokenIEOAddress = dictionary["token_ieo"] as? String ?? ""
    self.reserveAddress = dictionary["reserve"] as? String ?? ""
    self.etherScanEndpoint = dictionary["ethScanUrl"] as? String ?? ""
    self.tradeTopic = dictionary["trade_topic"] as? String ?? ""
    self.customRPC = CustomRPC(
      chainID: chainID,
      name: name,
      symbol: symbol,
      endpoint: endpoint
    )
  }
}
