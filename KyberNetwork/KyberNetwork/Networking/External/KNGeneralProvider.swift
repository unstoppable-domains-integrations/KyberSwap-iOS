// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit

class KNGeneralProvider {

  static let shared = KNGeneralProvider()

  lazy var web3Swift: Web3Swift = {
    if let customRPC = KNEnvironment.default.customRPC, let path = URL(string: customRPC.endpoint) {
      return Web3Swift(url: path)
    } else {
      return Web3Swift()
    }
  }()

  lazy var networkAddress: Address = {
    return Address(string: KNEnvironment.default.knCustomRPC?.networkAddress ?? "")!
  }()

  init() {
    DispatchQueue.main.async { self.web3Swift.start() }
  }

  // MARK: Balance
  func getETHBalanace(for address: String, completion: @escaping (Result<Balance, AnyError>) -> Void) {
    let request = EtherServiceRequest(batch: BatchFactory().create(BalanceRequest(address: address)))
    Session.send(request) { result in
      switch result {
      case .success(let balance):
        completion(.success(balance))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getTokenBalance(for address: Address, contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getTokenBalanceEncodeData(for: address) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceRequest(
          batch: BatchFactory().create(CallRequest(to: contract.description, data: data))
        )
        Session.send(request) { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let balance):
            self.getTokenBalanceDecodeData(from: balance, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: Transaction count
  func getTransactionCount(for address: String, completion: @escaping (Result<Int, AnyError>) -> Void) {
    let request = EtherServiceRequest(batch: BatchFactory().create(GetTransactionCountRequest(
      address: address,
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

  func getAllowance(for token: TokenObject, address: Address, networkAddress: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if token.isETH {
      // ETH no need to request for approval
      completion(.success(BigInt(2).power(255)))
      return
    }
    let tokenAddress: Address = Address(string: token.contract)!
    self.getTokenAllowanceEncodeData(for: address, networkAddress: networkAddress) { [weak self] dataResult in
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

  func getExpectedRate(from: TokenObject, to: TokenObject, amount: BigInt, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    let source: Address = Address(string: from.contract)!
    let dest: Address = Address(string: to.contract)!
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

  func approve(token: TokenObject, value: BigInt = BigInt(2).power(255), account: Account, keystore: Keystore, currentNonce: Int, networkAddress: Address, completion: @escaping (Result<Int, AnyError>) -> Void) {
    var error: Error?
    var encodeData: Data = Data()
    var txCount: Int = 0
    let group = DispatchGroup()

    group.enter()
    self.getSendApproveERC20TokenEncodeData(networkAddress: networkAddress, value: value, completion: { result in
      switch result {
      case .success(let resp):
        encodeData = resp
      case .failure(let err):
        error = err
      }
      group.leave()
    })
    group.enter()
    self.getTransactionCount(for: account.address.description) { result in
      switch result {
      case .success(let resp):
        txCount = max(resp, currentNonce)
      case .failure(let err):
        error = err
      }
      group.leave()
    }

    group.notify(queue: .main) {
      if let error = error {
        completion(.failure(AnyError(error)))
        return
      }
      self.signTransactionData(forApproving: token, account: account, nonce: txCount, data: encodeData, keystore: keystore, completion: { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let signData):
          self.sendSignedTransactionData(signData, completion: { sendResult in
            switch sendResult {
            case .success:
              completion(.success(txCount + 1))
            case .failure(let error):
              completion(.failure(error))
            }
          })
        case .failure(let error):
          completion(.failure(error))
        }
      })
    }
  }

  public func getUserCapInWei(for address: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getUserCapInWeiEncode(for: address) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let callReq = CallRequest(
          to: self.networkAddress.description,
          data: data
        )
        let ethService = EtherServiceRequest(batch: BatchFactory().create(callReq))
        DispatchQueue.global(qos: .background).async {
          Session.send(ethService) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let resp):
                self.getUserCapInWeiDecode(from: resp, completion: { decodeResult in
                  switch decodeResult {
                  case .success(let value):
                    completion(.success(value))
                  case .failure(let error):
                    completion(.failure(error))
                  }
                })
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
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
}

// MARK: Sign transaction
extension KNGeneralProvider {
  private func signTransactionData(forApproving token: TokenObject, account: Account, nonce: Int, data: Data, keystore: Keystore, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signTransaction = SignTransaction(
      value: BigInt(0),
      account: account,
      to: Address(string: token.contract),
      nonce: nonce,
      data: data,
      gasPrice: KNGasConfiguration.gasPriceDefault,
      gasLimit: KNGasConfiguration.exchangeTokensGasLimitDefault,
      chainID: KNEnvironment.default.chainID
    )
    let signResult = keystore.signTransaction(signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success(data))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }
}

// MARK: Web3Swift Encoding
extension KNGeneralProvider {
  fileprivate func getTokenBalanceEncodeData(for address: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC20BalanceEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getSendApproveERC20TokenEncodeData(networkAddress: Address, value: BigInt = BigInt(2).power(255), completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = ApproveERC20Encode(
      address: networkAddress,
      value: value
    )
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(Data(hex: data.drop0x)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getTokenAllowanceEncodeData(for address: Address, networkAddress: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetTokenAllowanceEndcode(
      ownerAddress: address,
      spenderAddress: networkAddress
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

  fileprivate func getExpectedRateEncodeData(source: Address, dest: Address, amount: BigInt, completion: @escaping (Result<String, AnyError>) -> Void) {
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

  fileprivate func getUserCapInWeiEncode(for address: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetUserCapInWeiEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

// MARK: Web3Swift Decoding
extension KNGeneralProvider {
  fileprivate func getTokenBalanceDecodeData(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(BigInt(0)))
      return
    }
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

  fileprivate func getTokenAllowanceDecodeData(_ data: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if data == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(BigInt(0)))
      return
    }
    let decodeRequest = KNGetTokenAllowanceDecode(data: data)
    self.web3Swift.request(request: decodeRequest, completion: { decodeResult in
      switch decodeResult {
      case .success(let value):
        let remain: BigInt = BigInt(value) ?? BigInt(0)
        completion(.success(remain))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    })
  }

  fileprivate func getExpectedRateDecodeData(rateData: String, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
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

  fileprivate func getUserCapInWeiDecode(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      completion(.success(BigInt(0)))
      return
    }
    let request = KNGetUserCapInWeiDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt(0)))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}
