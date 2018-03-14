// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore

class KNExternalProvider {

  let web3Swift: Web3Swift
  let knCustomRPC: KNCustomRPC!
  let networkAddress: Address!
  let reserveAddress: Address!

  init(web3: Web3Swift) {
    self.web3Swift = web3
    let customRPC: KNCustomRPC = KNEnvironment.default.knCustomRPC!
    self.knCustomRPC = customRPC
    self.networkAddress = Address(string: customRPC.networkAddress)
    self.reserveAddress = Address(string: customRPC.reserveAddress)
  }

  // MARK: Balance
  public func getETHBalance(address: Address, completion: @escaping (Result<Balance, AnyError>) -> Void) {
    let request = EtherServiceRequest(batch: BatchFactory().create(BalanceRequest(address: address.description)))
    Session.send(request) { result in
      switch result {
      case .success(let balance):
        completion(.success(balance))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  public func getTokenBalance(for address: Address, contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = GetERC20BalanceEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        let request2 = EtherServiceRequest(
          batch: BatchFactory().create(CallRequest(to: contract.description, data: res))
        )
        Session.send(request2) { [weak self] result2 in
          guard let `self` = self else { return }
          switch result2 {
          case .success(let balance):
            let request = GetERC20BalanceDecode(data: balance)
            self.web3Swift.request(request: request) { result in
              switch result {
              case .success(let res):
                completion(.success(BigInt(res) ?? BigInt()))
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  // MARK: Transaction
  func getTransactionCount(address: Address, completion: @escaping (Result<Int, AnyError>) -> Void) {
    let request = EtherServiceRequest(batch: BatchFactory().create(GetTransactionCountRequest(
      address: address.description,
      state: "latest"
    )))
    Session.send(request) { result in
      switch result {
      case .success(let count):
        completion(.success(count))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func sendSignedTransactionData(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    let batch = BatchFactory().create(SendRawTransactionRequest(signedTransaction: data.hexEncoded))
    let request = EtherServiceRequest(batch: batch)
    Session.send(request) { result in
      switch result {
      case .success(let transactionID):
        completion(.success(transactionID))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}
