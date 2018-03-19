// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNCustomRPC {

  let customRPC: CustomRPC
  let networkAddress: String
  let reserveAddress: String
  let etherScanEndpoint: String
  let tradeTopic: String

  init(dictionary: JSONDictionary) {
    let chainID: Int = dictionary["networkId"] as? Int ?? 0
    let name: String = dictionary["chainName"] as? String ?? ""
    let symbol = name
    var endpoint: String
    do {
      let connections: JSONDictionary = try kn_cast(dictionary["connections"])
      let https: [JSONDictionary] = try kn_cast(connections["http"])
      let endpointJSON: JSONDictionary = https.count > 1 ? https[1] : https[0]
      endpoint = try kn_cast(endpointJSON["endPoint"])
    } catch {
      endpoint = dictionary["endpoint"] as? String ?? ""
    }
    self.networkAddress = dictionary["network"] as? String ?? ""
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
