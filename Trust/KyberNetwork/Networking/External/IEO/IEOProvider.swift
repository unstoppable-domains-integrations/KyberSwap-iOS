// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
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

  func getETHBalance(for address: String, completion: @escaping (Result<Balance, AnyError>) -> Void) {
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
}
