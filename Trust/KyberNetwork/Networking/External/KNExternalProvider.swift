// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import JavaScriptKit

class KNExternalProvider {

  let keystore: Keystore
  let account: Account
  let web3Swift: Web3Swift
  let knCustomRPC: KNCustomRPC!
  let networkAddress: Address!
  let reserveAddress: Address!

  var minTxCount: Int = 0

  init(web3: Web3Swift, keystore: Keystore, account: Account) {
    self.keystore = keystore
    self.account = account
    self.web3Swift = web3
    let customRPC: KNCustomRPC = KNEnvironment.default.knCustomRPC!
    self.knCustomRPC = customRPC
    self.networkAddress = Address(string: customRPC.networkAddress)
    self.reserveAddress = Address(string: customRPC.reserveAddress)
  }

  // MARK: Balance
  public func getETHBalance(completion: @escaping (Result<Balance, AnyError>) -> Void) {
    let request = EtherServiceRequest(batch: BatchFactory().create(BalanceRequest(address: self.account.address.description)))
    Session.send(request) { result in
      switch result {
      case .success(let balance):
        completion(.success(balance))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  public func getTokenBalance(for contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getTokenBalanceEncodeData { [weak self] encodeResult in
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceRequest(
          batch: BatchFactory().create(CallRequest(to: contract.description, data: data))
        )
        Session.send(request) { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let balance):
            self.getTokenBalanceDecodeData(balance: balance, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: Transaction
  func getTransactionCount(completion: @escaping (Result<Int, AnyError>) -> Void) {
    let request = EtherServiceRequest(batch: BatchFactory().create(GetTransactionCountRequest(
      address: self.account.address.description,
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

  func transfer(transaction: UnconfirmedTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success(let count):
        self.minTxCount = max(self.minTxCount + 1, count)
        self.requestDataForTokenTransfer(transaction, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            self.signTransactionData(from: transaction, nounce: self.minTxCount, data: data, completion: { [weak self] signResult in
              guard let `self` = self else { return }
              switch signResult {
              case .success(let signData):
                self.sendSignedTransactionData(signData, completion: completion)
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(error))
          }
        })
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func exchange(exchange: KNDraftExchangeTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success(let count):
        self.minTxCount = max(self.minTxCount + 1, count)
        self.requestDataForTokenExchange(exchange, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            self.signTransactionData(from: exchange, nounce: self.minTxCount, data: data, completion: { [weak self] signResult in
              switch signResult {
              case .success(let signData):
                self?.sendSignedTransactionData(signData, completion: completion)
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getReceipt(for transaction: Transaction, completion: @escaping (Result<Transaction, AnyError>) -> Void) {
    let request = KNGetTransactionReceiptRequest(hash: transaction.id)
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let receipt):
        self.getExchangeTransactionDecode(receipt.logsData, completion: { decodeResult in
          let dict: JSONDictionary? = {
            if case .success(let json) = decodeResult {
              return json
            }
            return nil
          }()
          let newTransaction = receipt.toTransaction(from: transaction, logsDict: dict)
          completion(.success(newTransaction))
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getTransactionByHash(_ hash: String, completion: @escaping (SessionTaskError?) -> Void) {
    let request = GetTransactionRequest(hash: hash)
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success:
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }

  // If the value returned > 0 consider as allowed
  // should check with the current send amount, however the limit is likely set as very big
  func getAllowance(token: KNToken, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    if token.isETH {
      // ETH no need to request for approval
      completion(.success(true))
      return
    }
    let tokenAddress: Address
    do {
      tokenAddress = try kn_cast(Address(string: token.address))
    } catch let error {
      completion(.failure(AnyError(error)))
      return
    }
    self.getTokenAllowanceEncodeData { dataResult in
      switch dataResult {
      case .success(let data):
        let callRequest = CallRequest(to: tokenAddress.description, data: data)
        let getAllowanceRequest = EtherServiceRequest(batch: BatchFactory().create(callRequest))
        Session.send(getAllowanceRequest) { [weak self] getAllowanceResult in
          guard let `self` = self else { return }
          switch getAllowanceResult {
          case .success(let data):
            self.getTokenAllowanceDecodeData(data, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // Encode function, get transaction count, sign transaction, send signed data
  func sendApproveERC20Token(exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.requestSendApproveERC20TokenData { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        self.getTransactionCount { [weak self] txCountResult in
          guard let `self` = self else { return }
          switch txCountResult {
          case .success(let count):
            self.minTxCount = max(self.minTxCount + 1, count)
            self.signTransactionData(forApproving: exchangeTransaction.from, nouce: self.minTxCount, data: data, completion: { [weak self] signResult in
              switch signResult {
              case .success(let signData):
                self?.sendSignedTransactionData(signData, completion: { sendResult in
                  switch sendResult {
                  case .success:
                    completion(.success(true))
                  case .failure(let error):
                    completion(.failure(error))
                  }
                })
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            })
          case .failure(let error):
            completion(.failure(error))
          }
        }
      case .failure(let error):
        completion(.failure(error))
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

  // MARK: Rate
  func getExpectedRate(from: KNToken, to: KNToken, amount: BigInt, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    var source: Address!
    var dest: Address!
    do {
      source = try kn_cast(Address(string: from.address))
      dest = try kn_cast(Address(string: to.address))
    } catch let error {
      completion(.failure(AnyError(error)))
      return
    }
    self.getExpectedRateEncodeData(source: source, dest: dest, amount: amount) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        let callRequest = CallRequest(to: self.networkAddress.description, data: data)
        let getRateRequest = EtherServiceRequest(batch: BatchFactory().create(callRequest))
        Session.send(getRateRequest) { [weak self] getRateResult in
          guard let `self` = self else { return }
          switch getRateResult {
          case .success(let rateData):
            self.getExpectedRateDecodeData(rateData: rateData, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  // MARK: Estimate Gas
  func getEstimateGasLimit(for transferTransaction: UnconfirmedTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {

    let defaultGasLimit: BigInt = {
      if transferTransaction.transferType.isETHTransfer() {
        return KNGasConfiguration.transferETHGasLimitDefault
      }
      return KNGasConfiguration.transferTokenGasLimitDefault
    }()
    self.requestDataForTokenTransfer(transferTransaction) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        self.estimateGasLimit(
          from: self.account.address,
          to: self.addressToSend(transferTransaction),
          value: self.valueToSend(transferTransaction),
          data: data,
          defaultGasLimit: defaultGasLimit,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getEstimateGasLimit(for exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let fromAddress: Address = self.account.address
    let toAddress: Address = self.networkAddress
    let value: BigInt = exchangeTransaction.from.isETH ? exchangeTransaction.amount : BigInt(0)

    let defaultGasLimit: BigInt = {
      return KNGasConfiguration.exchangeTokensGasLimitDefault
    }()

    self.requestDataForTokenExchange(exchangeTransaction) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        self.estimateGasLimit(
          from: fromAddress,
          to: toAddress,
          value: value,
          data: data,
          defaultGasLimit: defaultGasLimit,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  fileprivate func estimateGasLimit(from fromAddr: Address, to toAddr: Address?, value: BigInt, data: Data, defaultGasLimit: BigInt, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = EstimateGasRequest(
      from: fromAddr,
      to: toAddr,
      value: value,
      data: data
    )
    NSLog("------ Estimate gas used ------")
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success(let value):
        let gasLimit: BigInt = {
          var limit = BigInt(value.drop0x, radix: 16) ?? BigInt()
          limit += (limit * 20 / 100)
          return min(limit, defaultGasLimit)
        }()
        NSLog("------ Estimate gas used: \(gasLimit.fullString(units: .wei)) ------")
        completion(.success(gasLimit))
      case .failure(let error):
        NSLog("------ Estimate gas used failed: \(error.localizedDescription) ------")
        completion(.failure(AnyError(error)))
      }
    }
  }

  // MARK: Sign transaction
  private func signTransactionData(from transaction: UnconfirmedTransaction, nounce: Int, data: Data?, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let defaultGasLimit: BigInt = transaction.transferType.isETHTransfer() ? KNGasConfiguration.transferETHGasLimitDefault : KNGasConfiguration.transferTokenGasLimitDefault
    let signTransaction: SignTransaction = SignTransaction(
      value: self.valueToSend(transaction),
      account: self.account,
      to: self.addressToSend(transaction),
      nonce: nounce,
      data: data ?? Data(),
      gasPrice: transaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: transaction.gasLimit ?? defaultGasLimit,
      chainID: KNEnvironment.default.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(from exchange: KNDraftExchangeTransaction, nounce: Int, data: Data, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signTransaction: SignTransaction = SignTransaction(
      value: exchange.from.isETH ? exchange.amount : BigInt(0),
      account: self.account,
      to: self.networkAddress,
      nonce: nounce,
      data: data,
      gasPrice: exchange.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: exchange.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault,
      chainID: KNEnvironment.default.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(forApproving token: KNToken, nouce: Int, data: Data, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signTransaction = SignTransaction(
      value: BigInt(0),
      account: account,
      to: Address(string: token.address),
      nonce: nouce,
      data: data,
      gasPrice: KNGasConfiguration.gasPriceDefault,
      gasLimit: KNGasConfiguration.exchangeTokensGasLimitDefault,
      chainID: KNEnvironment.default.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(from signTransaction: SignTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signResult = self.keystore.signTransaction(signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success(data))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }

  // MARK: Web3Swift Request
  func getTokenBalanceEncodeData(completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC20BalanceEncode(address: self.account.address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getTokenBalanceDecodeData(balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = GetERC20BalanceDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt()))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getTokenAllowanceEncodeData(completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetTokenAllowanceEndcode(
      ownerAddress: self.account.address,
      spenderAddress: self.networkAddress
    )
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getTokenAllowanceDecodeData(_ data: String, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    let decodeRequest = KNGetTokenAllowanceDecode(data: data)
    self.web3Swift.request(request: decodeRequest, completion: { decodeResult in
      switch decodeResult {
      case .success(let value):
        let remain: BigInt = BigInt(value) ?? BigInt(0)
        completion(.success(!remain.isZero))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    })
  }

  func getExpectedRateEncodeData(source: Address, dest: Address, amount: BigInt, completion: @escaping (Result<String, AnyError>) -> Void) {
    let encodeRequest = KNGetExpectedRateEncode(source: source, dest: dest, amount: amount)
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getExpectedRateDecodeData(rateData: String, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    //TODO (Mike): Currently decoding is always return invalid return type even though the response type is correct
    let decodeRequest = KNGetExpectedRateDecode(data: rateData)
    self.web3Swift.request(request: decodeRequest, completion: { (result) in
      switch result {
      case .success(let decodeData):
        let expectedRate = decodeData["expectedRate"] ?? ""
        let slippageRate = decodeData["slippageRate"] ?? ""
        completion(.success((BigInt(expectedRate) ?? BigInt(0), BigInt(slippageRate) ?? BigInt(0))))
      case .failure(let error):
        if let err = error.error as? JSErrorDomain {
          // Temporary fix for expected rate request
          if case .invalidReturnType(let object) = err, let json = object as? JSONDictionary {
            if let expectedRate = json["expectedRate"] as? String, let slippageRate = json["slippageRate"] as? String {
              completion(.success((BigInt(expectedRate) ?? BigInt(0), BigInt(slippageRate) ?? BigInt(0))))
              return
            }
          }
        }
        completion(.failure(AnyError(error)))
      }
    })
  }

  func getExchangeTransactionDecode(_ data: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = KNExchangeEvenDataDecode(data: data)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let json):
        completion(.success(json))
      case .failure(let error):
        if let err = error.error as? JSErrorDomain {
          if case .invalidReturnType(let object) = err, let json = object as? JSONDictionary {
            completion(.success(json))
            return
          }
        }
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenTransfer(_ transaction: UnconfirmedTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    if case .ether = transaction.transferType {
      completion(.success(transaction.data ?? Data()))
      return
    }
    self.web3Swift.request(request: ContractERC20Transfer(amount: transaction.value, address: transaction.to?.description ?? "")) { (result) in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenExchange(_ exchange: KNDraftExchangeTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = KNExchangeRequestEncode(exchange: exchange, address: self.account.address)
    self.web3Swift.request(request: encodeRequest) { result in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestSendApproveERC20TokenData(completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = ApproveERC20Encode(address: self.networkAddress, value: BigInt(2).power(255))
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(Data(hex: data.drop0x)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  // MARK: Helper
  private func valueToSend(_ transaction: UnconfirmedTransaction) -> BigInt {
    return transaction.transferType.isETHTransfer() ? transaction.value : BigInt(0)
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
}
