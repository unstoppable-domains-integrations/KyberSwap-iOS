// Copyright SIX DAY LLC. All rights reserved.

import Moya
import CryptoSwift

enum KyberNetworkService: String {
  case getRate = "/getRate"
  case getRateUSD = "/getRateUSD"
  case getHistoryOneColumn = "/getHistoryOneColumn"
  case getLatestBlock = "/getLatestBlock"
  case getKyberEnabled = "/getKyberEnabled"
  case getMaxGasPrice = "/getMaxGasPrice"
  case getGasPrice = "/getGasPrice"
}

extension KyberNetworkService: TargetType {

  var baseURL: URL {
    let baseURLString = KNEnvironment.internalBaseEndpoint
    return URL(string: baseURLString)!
  }

  var path: String {
    return self.rawValue
  }

  var method: Moya.Method {
    return .get
  }

  var task: Task {
    return .requestPlain
  }

  var sampleData: Data {
    return Data() // sample data for UITest
  }

  var headers: [String: String]? {
    return [
      "content-type": "application/json",
      "client": Bundle.main.bundleIdentifier ?? "",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}

enum KNTrackerService {
  case getTrades(fromDate: Date?, toDate: Date?, address: String)
  case getSupportedTokens()
  case getChartHistory(symbol: String, resolution: String, from: Int64, to: Int64, rateType: String)
  case getRates()
}

extension KNTrackerService: TargetType {
  var baseURL: URL {
    let baseURLString = KNEnvironment.internalTrackerEndpoint
    switch self {
    case .getTrades(let fromDate, let toDate, let address):
      let path: String = {
        var path = "/api/search?q=\(address)&exportData=true"
        if let date = fromDate {
          path += "&fromDate=\(date.timeIntervalSince1970)"
        }
        if let date = toDate {
          path += "&toDate=\(date.timeIntervalSince1970)"
        }
        return path
      }()
      return URL(string: baseURLString + path)!
    case .getSupportedTokens:
      return URL(string: baseURLString + "/api/tokens/supported")!
    case .getChartHistory(let symbol, let resolution, let from, let to, let rateType):
      let url = "/chart/history?symbol=\(symbol)&resolution=\(resolution)&from=\(from)&to=\(to)&rateType=\(rateType)"
      return URL(string: baseURLString + url)!
    case .getRates:
      return URL(string: baseURLString + "/api/change24h?usd=1")!
    }
  }

  var path: String {
    return ""
  }

  var method: Moya.Method {
    return .get
  }

  var task: Task {
    return .requestPlain
  }

  var sampleData: Data {
    return Data() // sample data for UITest
  }

  var headers: [String: String]? {
    return [
      "content-type": "application/json",
      "client": Bundle.main.bundleIdentifier ?? "",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}

enum KyberGOService {
  case listIEOs
  case getAccessToken(code: String)
  case getUserInfo(accessToken: String)
  case checkParticipate(accessToken: String, ieoID: Int)
  case getSignedTx(userID: Int, ieoID: Int, address: String, time: UInt)
  case getTxList(accessToken: String)
  case createTx(ieoID: Int, srcAddress: String, hash: String, accessToken: String)
  case markView
}

extension KyberGOService: TargetType {
  var baseURL: URL {
    let baseString = KNAppTracker.getKyberGOBaseString()
    switch self {
    case .listIEOs:
      return URL(string: "\(baseString)/api/ieos")!
    case .getAccessToken:
      return URL(string: "\(baseString)/oauth/token")!
    case .getUserInfo:
      return URL(string: "\(baseString)/api/user_info")!
    case .checkParticipate:
      return URL(string: "\(baseString)/api/can_participate_ieo")!
    case .getSignedTx:
      return URL(string: KNSecret.ieoSignedEndpoint)!
    case .getTxList:
      return URL(string: "\(baseString)/api/txs")!
    case .createTx:
      return URL(string: "\(baseString)/api/txs")!
    case .markView:
      return URL(string: "\(baseString)/api/txs/set_viewed_txs")!
    }
  }

  var path: String { return "" }

  var method: Moya.Method {
    switch self {
    case .listIEOs, .getUserInfo, .checkParticipate, .getTxList: return .get
    default: return .post
    }
  }

  var task: Task {
    switch self {
    case .listIEOs, .markView: return .requestPlain
    case .getAccessToken(let code):
      //TODO: Change to prod app id and secret
      let json: JSONDictionary = [
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": KNSecret.redirectURL,
        "client_id": KNSecret.debugAppID,
        "client_secret": KNSecret.debugSecret,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .checkParticipate(let accessToken, let ieoID):
      let json: JSONDictionary = [
        "client_id": KNSecret.debugAppID,
        "client_secret": KNSecret.debugSecret,
        "access_token": accessToken,
        "ieo_id": ieoID,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .getUserInfo(let accessToken):
      let json: JSONDictionary = [ "access_token": accessToken ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .getTxList(let accessToken):
      let json: JSONDictionary = [
        "client_id": KNSecret.debugAppID,
        "client_secret": KNSecret.debugSecret,
        "access_token": accessToken,
        ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .getSignedTx(let userID, let ieoID, let address, let time):
      let params: JSONDictionary = [
        "contributor": address,
        "ieoid": ieoID,
        "nonce": time,
        "userid": userID,
      ]
      return .requestCompositeData(bodyData: Data(), urlParameters: params)
    case .createTx(let ieoID, let srcAddress, let hash, let accessToken):
      let json: JSONDictionary = [
        "client_id": KNSecret.debugAppID,
        "client_secret": KNSecret.debugSecret,
        "access_token": accessToken,
        "ieo_id": ieoID,
        "hash": hash,
        "source_address": srcAddress,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    }
  }
  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    switch self {
    case .getSignedTx(let userID, let ieoID, let address, let time):
      let string = "contributor=\(address)&ieoid=\(ieoID)&nonce=\(time)&userid=\(userID)"
      let hmac = try! HMAC(key: KNSecret.ieoSignedKey, variant: .sha512)
      let hash = try! hmac.authenticate(string.bytes).toHexString()
      return [
        "Content-Type": "application/x-www-form-urlencoded",
        "signed": hash,
        "client": Bundle.main.bundleIdentifier ?? "",
        "client-build": Bundle.main.buildNumber ?? "",
      ]
    default:
      return [
        "content-type": "application/json",
        "client": Bundle.main.bundleIdentifier ?? "",
        "client-build": Bundle.main.buildNumber ?? "",
      ]
    }
  }
}
