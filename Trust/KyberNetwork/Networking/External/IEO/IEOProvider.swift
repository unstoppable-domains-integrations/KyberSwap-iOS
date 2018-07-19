// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit

class IEOProvider {

  static let shared: IEOProvider = IEOProvider()

  lazy var web3Swift: Web3Swift = {
    if let customRPC = KNEnvironment.default.customRPC, let path = URL(string: customRPC.endpoint) {
      return Web3Swift(url: path)
    } else {
      return Web3Swift()
    }
  }()

  init() { self.web3Swift.start() }

  /*
   Get ETH Balance for a given address in IEO
   */
  func getBalance(for address: String, token: TokenObject, completion: @escaping (Result<Balance, AnyError>) -> Void) {
    if token.isETH {
      KNGeneralProvider.shared.getETHBalanace(for: address, completion: completion)
    } else {
      KNGeneralProvider.shared.getTokenBalance(for: Address(string: address)!, contract: token.address) { result in
        switch result {
        case .success(let value):
          completion(.success(Balance(value: value)))
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }

  /*
   Get current distributed tokens wei for a given address in IEO
   */
  func getDistributedTokensWei(for address: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let encodeRequest = IEODistributedTokensWeiEncode()
    self.web3Swift.request(request: encodeRequest) { result in
      switch result {
      case .success(let encodeData):
        let request = EtherServiceRequest(batch: BatchFactory().create(CallRequest(to: address, data: encodeData)))
        Session.send(request) { result in
          switch result {
          case .success(let data):
            let decodeRequest = IEODistributedTokensWeiDecode(data: data)
            self.web3Swift.request(request: decodeRequest, completion: { decodeResult in
              switch decodeResult {
              case .success(let value):
                completion(.success(BigInt(value) ?? BigInt()))
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            })
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  /*
   Get current rate in ICO phase for a given IEO contract
   */
  func getRate(for address: String, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    let encodeRequest = IEOGetRateEncode()
    self.web3Swift.request(request: encodeRequest) { result in
      switch result {
      case .success(let encodeData):
        let request = EtherServiceRequest(batch: BatchFactory().create(CallRequest(to: address, data: encodeData)))
        Session.send(request) { result in
          switch result {
          case .success(let data):
            let decodeRequest = IEOGetRateDecode(data: data)
            self.web3Swift.request(request: decodeRequest, completion: { decodeResult in
              switch decodeResult {
              case .success(let decodeData):
                let numerator = decodeData["rateNumerator"] ?? ""
                let denominator = decodeData["rateDenominator"] ?? ""
                completion(.success((BigInt(numerator) ?? BigInt(0), BigInt(denominator) ?? BigInt(0))))
              case .failure(let error):
                if let err = error.error as? JSErrorDomain {
                  // Temporary fix for rate request
                  if case .invalidReturnType(let object) = err, let json = object as? JSONDictionary {
                    if let numerator = json["rateNumerator"] as? String, let denominator = json["rateDenominator"] as? String {
                      completion(.success((BigInt(numerator) ?? BigInt(0), BigInt(denominator) ?? BigInt(0))))
                      return
                    }
                  }
                }
                completion(.failure(AnyError(error)))
              }
            })
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  /*
   Check if a given address is in whitelisted list of a IEO
   - contractAddress: Address of the IEO
   - address: address to check whitelisted
   */
  func checkWhiteListedAddress(contractAddress: String, address: Address, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    let encodeRequest = IEOCheckWhiteListedAddressEncode(address: address)
    self.web3Swift.request(request: encodeRequest) { [weak self] encodeResult in
      guard let _ = self else { return }
      switch encodeResult {
      case .success(let encodeData):
        let request = EtherServiceRequest(batch: BatchFactory().create(CallRequest(to: contractAddress, data: encodeData)))
        Session.send(request) { [weak self] result in
          guard let _ = self else { return }
          switch result {
          case .success(let data):
            completion(.success(!(data == "0x" || data == "0x0")))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  /*
   Get contributor remaining cap from node, there are 2 phases, in the first phase user is limited cap until cap lifted time
   - contractAddress: Address of the IEO
   - userID: Current user ID
  */
  func getContributorRemainingCap(contractAddress: String, userID: Int, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let encodeRequest = IEOGetContridbutorRemainingCapEncode(userID: userID)
    self.web3Swift.request(request: encodeRequest) { [weak self] encodeResult in
      guard let _ = self else { return }
      switch encodeResult {
      case .success(let encodeData):
        let request = EtherServiceRequest(batch: BatchFactory().create(CallRequest(to: contractAddress, data: encodeData)))
        Session.send(request) { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let data):
            if data == "0x" {
              // Web3 failed to decode 0x
              completion(.success(BigInt(0)))
              return
            }
            let decodeRequest = IEOGetContridbutorRemainingCapDecode(data: data)
            self.web3Swift.request(request: decodeRequest, completion: { [weak self] decodeResult in
              guard let _ = self else { return }
              switch decodeResult {
              case .success(let resp):
                completion(.success(BigInt(resp) ?? BigInt(0)))
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            })
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func buy(transaction: IEODraftTransaction, account: Account, keystore: Keystore, completion: @escaping (Result<String, AnyError>) -> Void) {
    if transaction.token.isETH {
      self.buyWithETH(transaction: transaction, account: account, keystore: keystore, completion: completion)
    } else {
      self.buyWithToken(transaction: transaction, account: account, keystore: keystore, completion: completion)
    }
  }

  fileprivate func buyWithETH(transaction: IEODraftTransaction, account: Account, keystore: Keystore, completion: @escaping (Result<String, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTransactionCount(for: account.address.description) { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success(let count):
        transaction.nonce = count
        self.getIEOContributeEncodeData(
          transaction: transaction,
          completion: { [weak self] encodeResult in
          guard let _ = self else { return }
          switch encodeResult {
          case .success(let encodeData):
            transaction.data = encodeData
            self?.signTransaction(transaction: transaction, account: account, keystore: keystore, completion: { signedResult in
              switch signedResult {
              case .success(let data):
                KNGeneralProvider.shared.sendSignedTransactionData(data, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
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

  fileprivate func buyWithToken(transaction: IEODraftTransaction, account: Account, keystore: Keystore, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.preProcessForBuyingWithToken(transaction: transaction, account: account, keystore: keystore) { [weak self] preProcessResult in
      guard let `self` = self else { return }
      switch preProcessResult {
      case .success(let count):
        transaction.nonce = count
        self.getIEOContributeWithTokenData(transaction: transaction, completion: { [weak self] encodeResult in
          guard let `self` = self else { return }
          switch encodeResult {
          case .success(let encodeData):
            transaction.data = encodeData
            self.signTransaction(transaction: transaction, account: account, keystore: keystore, completion: { signedResult in
              switch signedResult {
              case .success(let data):
                KNGeneralProvider.shared.sendSignedTransactionData(data, completion: completion)
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

  fileprivate func preProcessForBuyingWithToken(transaction: IEODraftTransaction, account: Account, keystore: Keystore, completion: @escaping (Result<Int, AnyError>) -> Void) {
    let tokenIEOAddress: Address = Address(string: KNEnvironment.default.knCustomRPC?.tokenIEOAddress ?? "")!
    KNGeneralProvider.shared.getAllowance(for: transaction.token, address: account.address, networkAddress: tokenIEOAddress) { result in
      switch result {
      case .success(let allow):
        if allow {
          KNGeneralProvider.shared.getTransactionCount(for: account.address.description, completion: completion)
          return
        }
        let tokenIEOAddress: Address = Address(string: KNEnvironment.default.knCustomRPC?.tokenIEOAddress ?? "")!
        KNGeneralProvider.shared.approve(token: transaction.token, account: account, keystore: keystore, networkAddress: tokenIEOAddress, completion: completion)
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getIEOContributeEncodeData(transaction: IEODraftTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    if transaction.token.isETH {
      self.getIEOContributeETHEncodeData(transaction: transaction, completion: completion)
    } else {
      self.getIEOContributeWithTokenData(transaction: transaction, completion: completion)
    }
  }

  fileprivate func getIEOContributeETHEncodeData(transaction: IEODraftTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let request = IEOContributeEncode(transaction: transaction)
    self.web3Swift.request(request: request) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        completion(.success(Data(hex: data.drop0x)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getIEOContributeWithTokenData(transaction: IEODraftTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let request = IEOContributeWithTokenEncode(transaction: transaction)
    self.web3Swift.request(request: request) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        completion(.success(Data(hex: data.drop0x)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getEstimateGasLimit(for transaction: IEODraftTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let defaultGasLimit: BigInt = {
      return KNGasConfiguration.transferETHBuyTokenSaleGasLimitDefault
    }()
    self.getIEOContributeEncodeData(transaction: transaction) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: transaction.wallet.address,
          to: transaction.ieo.contract,
          gasPrice: transaction.gasPrice,
          value: transaction.amount,
          data: data,
          defaultGasLimit: defaultGasLimit,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func signTransaction(transaction: IEODraftTransaction, account: Account, keystore: Keystore, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let value: BigInt = transaction.token.isETH ? transaction.amount : BigInt(0)
    let to: Address? = transaction.token.isETH ? Address(string: transaction.ieo.contract) : Address(string: KNEnvironment.default.knCustomRPC?.tokenIEOAddress ?? "")
    let signTransaction = SignTransaction(
      value: value,
      account: account,
      to: to,
      nonce: transaction.nonce,
      data: transaction.data ?? Data(),
      gasPrice: transaction.gasPrice,
      gasLimit: transaction.gasLimit,
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
