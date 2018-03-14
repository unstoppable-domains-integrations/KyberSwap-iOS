// Copyright SIX DAY LLC. All rights reserved.

import APIKit
import JSONRPCKit
import Result
import BigInt
import TrustKeystore
import JavaScriptKit

class KNTransactionCoordinator {

  let session: KNSession

  fileprivate var minTxCount: Int = 0

  init(session: KNSession) {
    self.session = session
  }

  func getTransactionCount(completion: @escaping (Result<Int, AnyError>) -> Void) {
    let request = EtherServiceRequest(batch: BatchFactory().create(GetTransactionCountRequest(
      address: self.session.wallet.address.description,
      state: "latest"
    )))
    Session.send(request) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let count):
        self.minTxCount = max(self.minTxCount + 1, count)
        completion(.success(self.minTxCount))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenTransfer(_ transaction: UnconfirmedTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    if case .ether = transaction.transferType {
      completion(.success(transaction.data ?? Data()))
      return
    }
    self.session.web3Swift.request(request: ContractERC20Transfer(amount: transaction.value, address: transaction.to!.description)) { (result) in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func signAndSend(_ transaction: UnconfirmedTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] (getCountResult) in
      guard let `self` = self else { return }
      switch getCountResult {
      case .success(let count):
        self.requestDataForTokenTransfer(transaction, completion: { [weak self] (dataResult) in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            let signTransaction = self.signTransaction(transaction, nounce: count, data: data)
            self.sendSignedTransaction(signTransaction, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func sendSignedTransaction(_ transaction: SignTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    let keystoreSignTransaction = self.session.keystore.signTransaction(transaction)
    switch keystoreSignTransaction {
    case .success(let data):
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
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }

  private func signTransaction(_ transaction: UnconfirmedTransaction, nounce: Int, data: Data?) -> SignTransaction {
    let signTransaction: SignTransaction = SignTransaction(
      value: self.valueToSend(transaction),
      account: self.getAccount()!,
      to: self.addressToSend(transaction),
      nonce: nounce,
      data: data ?? Data(),
      gasPrice: transaction.gasPrice ?? GasPriceConfiguration.default,
      gasLimit: transaction.gasLimit ?? GasLimitConfiguration.default,
      chainID: KNEnvironment.default.chainID
    )
    return signTransaction
  }

  private func signExchangeTransaction(_ exchange: KNDraftExchangeTransaction, nounce: Int, data: Data) -> SignTransaction {
    let signTransaction: SignTransaction = SignTransaction(
      value: exchange.from.isETH ? exchange.amount : BigInt(0),
      account: self.getAccount()!,
      to: self.session.externalProvider.networkAddress,
      nonce: nounce,
      data: data,
      gasPrice: exchange.gasPrice ?? GasPriceConfiguration.default,
      gasLimit: exchange.gasLimit ?? GasLimitConfiguration.default,
      chainID: KNEnvironment.default.chainID
    )
    return signTransaction
  }

  private func valueToSend(_ transaction: UnconfirmedTransaction) -> BigInt {
    let value: BigInt = {
      switch transaction.transferType {
      case .ether: return transaction.value
      default: return BigInt(0)
      }
    }()
    return value
  }

  private func addressToSend(_ transaction: UnconfirmedTransaction) -> Address? {
    let address: Address? = {
      switch transaction.transferType {
      case .ether: return transaction.to
      case .token(let token):
        return token.address
      }
    }()
    return address
  }

  private func getAccount() -> Account? {
    switch self.session.wallet.type {
    case .real(let account):
      return account
    case .watch:
      return nil
    }
  }
}
