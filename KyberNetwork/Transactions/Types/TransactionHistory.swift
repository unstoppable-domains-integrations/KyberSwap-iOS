//
//  TransactionHistory.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/8/21.
//

import Foundation

enum HistoryModelType {
  case swap
  case withdraw
  case transferETH
  case receiveETH
  case transferToken
  case receiveToken
  case allowance
  case earn
  case contractInteraction
  case selfTransfer
  
  static func typeFromInput(_ input: String) -> HistoryModelType {
    guard !input.isEmpty, input != "0x"  else {
      return .transferETH
    }
    
    let prefix = input.prefix(10)
    switch prefix {
    case "0x095ea7b3":
      return .allowance
    case "0x818e80b7", "0xdb006a75":
      return .withdraw
    case "0x30037de5", "0x9059232f":
      return .earn
    case "0xa9059cbb":
      return .transferToken
    case "0xcf512b53", "0x12342114", "0xae591d54":
      return .swap
    default:
      return .contractInteraction
    }
  }
}

struct HistoryTransaction {
  let type: HistoryModelType
  let timestamp: String
  let transacton: [EtherscanTransaction]
  let internalTransactions: [EtherscanInternalTransaction]
  let tokenTransactions: [EtherscanTokenTransaction]
  let wallet: String
  
  var date: Date {
    return Date(timeIntervalSince1970: Double(self.timestamp) ?? 0)
  }
}

struct InternalListResponse: Codable {
    let status, message: String
    let result: [EtherscanInternalTransaction]
}

struct EtherscanInternalTransaction: Codable, Equatable {
  static func == (lhs: EtherscanInternalTransaction, rhs: EtherscanInternalTransaction) -> Bool {
    return lhs.hash == rhs.hash
  }
    let blockNumber, timeStamp, hash, from: String
    let to, value, contractAddress, input: String
    let type, gas, gasUsed, traceID: String
    let isError, errCode: String

    enum CodingKeys: String, CodingKey {
        case blockNumber, timeStamp, hash, from, to, value, contractAddress, input, type, gas, gasUsed
        case traceID = "traceId"
        case isError, errCode
    }
}

struct TokenTransactionListResponse: Codable {
    let status, message: String
    let result: [EtherscanTokenTransaction]
}

struct EtherscanTokenTransaction: Codable, Equatable {
  static func == (lhs: EtherscanTokenTransaction, rhs: EtherscanTokenTransaction) -> Bool {
    return lhs.blockNumber == rhs.blockNumber
      && lhs.timeStamp == rhs.timeStamp
      && lhs.hash == rhs.hash
      && lhs.nonce == rhs.nonce
      && lhs.blockHash == rhs.blockHash
      && lhs.from == rhs.from
      && lhs.contractAddress == rhs.contractAddress
      && lhs.to == rhs.to
      && lhs.value == rhs.value
  }
  
    let blockNumber, timeStamp, hash, nonce: String
    let blockHash, from, contractAddress, to: String
    let value, tokenName, tokenSymbol, tokenDecimal: String
    let transactionIndex, gas, gasPrice, gasUsed: String
    let cumulativeGasUsed, input, confirmations: String
}

struct TransactionsListResponse: Codable {
    let status, message: String
    let result: [EtherscanTransaction]
}

struct EtherscanTransaction: Codable, Equatable {
  static func == (lhs: EtherscanTransaction, rhs: EtherscanTransaction) -> Bool {
    return lhs.hash == rhs.hash
  }
  
    let blockNumber, timeStamp, hash, nonce: String
    let blockHash, transactionIndex, from, to: String
    let value, gas, gasPrice, isError: String
    let txreceiptStatus, input, contractAddress, cumulativeGasUsed: String
    let gasUsed, confirmations: String

    enum CodingKeys: String, CodingKey {
        case blockNumber, timeStamp, hash, nonce, blockHash, transactionIndex, from, to, value, gas, gasPrice, isError
        case txreceiptStatus = "txreceipt_status"
        case input, contractAddress, cumulativeGasUsed, gasUsed, confirmations
    }
}
