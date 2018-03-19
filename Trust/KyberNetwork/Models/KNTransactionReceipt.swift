// Copyright SIX DAY LLC. All rights reserved.

import BigInt

struct KNTransactionReceipt: Decodable {
  let id: String
  let index: String
  let blockHash: String
  let blockNumber: String
  let gasUsed: String
  let cumulativeGasUsed: String
  let contractAddress: String
  let logsData: String
  let logsBloom: String
  let status: String
}

extension KNTransactionReceipt {
  static func from(_ dictionary: JSONDictionary) -> KNTransactionReceipt? {
    let id = dictionary["transactionHash"] as? String ?? ""
    let index = dictionary["transactionIndex"] as? String ?? ""
    let blockHash = dictionary["blockHash"] as? String ?? ""
    let blockNumber = dictionary["blockNumber"] as? String ?? ""
    let cumulativeGasUsed = dictionary["cumulativeGasUsed"] as? String ?? ""
    let gasUsed = dictionary["gasUsed"] as? String ?? ""
    let contractAddress = dictionary["contractAddress"] as? String ?? ""
    let logsData: String = {
      if let logs: [JSONDictionary] = dictionary["logs"] as? [JSONDictionary] {
        for log in logs {
          let address = log["address"] as? String ?? ""
          let topics = log["topics"] as? [String] ?? []
          let data = log["data"] as? String ?? ""
          if let customRPC = KNEnvironment.default.knCustomRPC, address == customRPC.networkAddress, topics.first == customRPC.tradeTopic {
            return data
          }
        }
      }
      return ""
    }()

    let logsBloom = dictionary["logsBloom"] as? String ?? ""
    let status = dictionary["status"] as? String ?? ""

    return KNTransactionReceipt(
      id: id,
      index: index.drop0x,
      blockHash: blockHash,
      blockNumber: BigInt(blockNumber.drop0x, radix: 16)?.description ?? "",
      gasUsed: BigInt(gasUsed.drop0x, radix: 16)?.description ?? "",
      cumulativeGasUsed: BigInt(cumulativeGasUsed.drop0x, radix: 16)?.description ?? "",
      contractAddress: contractAddress,
      logsData: logsData,
      logsBloom: logsBloom,
      status: status.drop0x
    )
  }
}
