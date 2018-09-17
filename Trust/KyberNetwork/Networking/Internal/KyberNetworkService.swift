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
  case getRates
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
  case getAccessToken(code: String, isRefresh: Bool)
  case getUserInfo(accessToken: String)
  case checkParticipate(accessToken: String, ieoID: Int)
  case getSignedTx(userID: Int, ieoID: Int, address: String, time: UInt)
  case getTxList(accessToken: String)
  case createTx(ieoID: Int, srcAddress: String, hash: String, accessToken: String)
  case markView(accessToken: String)
}

extension KyberGOService: TargetType {
  var baseURL: URL {
    let baseString = KNAppTracker.getKyberProfileBaseString()
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
    let clientID = KNEnvironment.default == .ropsten ? KNSecret.debugAppID : KNSecret.appID
    let clientSecret = KNEnvironment.default == .ropsten ? KNSecret.debugSecret : KNSecret.secret
    let redirectURL = KNEnvironment.default == .ropsten ? KNSecret.debugRedirectURL : KNSecret.redirectURL
    switch self {
    case .listIEOs: return .requestPlain
    case .getAccessToken(let code, let isRefresh):
      var json: JSONDictionary = [
        "grant_type": isRefresh ? "refresh_token" : "authorization_code",
        "redirect_uri": redirectURL,
        "client_id": clientID,
        "client_secret": clientSecret,
      ]
      if isRefresh {
        json["refresh_token"] = code
      } else {
        json["code"] = code
      }
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .checkParticipate(let accessToken, let ieoID):
      let json: JSONDictionary = [
        "client_id": clientID,
        "client_secret": clientSecret,
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
        "client_id": clientID,
        "client_secret": clientSecret,
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
        "client_id": clientSecret,
        "client_secret": clientSecret,
        "access_token": accessToken,
        "ieo_id": ieoID,
        "hash": hash,
        "source_address": srcAddress,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .markView(let accessToken):
      let json: JSONDictionary = [
        "client_id": clientID,
        "client_secret": clientSecret,
        "access_token": accessToken,
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

enum ProfileKYCService {
  case personalInfo(accessToken: String, firstName: String, lastName: String, gender: Bool, dob: String, nationality: String, country: String, wallets: [(String, String)])
  case identityInfo(accessToken: String, documentType: String, documentID: String, docImage: Data, docHoldingImage: Data)
  case submitKYC(accessToken: String)
  case userWallets(accessToken: String)
  case checkWalletExist(accessToken: String, wallet: String)

  var apiPath: String {
    switch self {
    case .personalInfo: return KNSecret.personalInfoEndpoint
    case .identityInfo: return KNSecret.identityInfoEndpoint
    case .submitKYC: return KNSecret.submitKYCEndpoint
    case .userWallets: return KNSecret.userWalletsEndpoint
    case .checkWalletExist: return KNSecret.checkWalletsExistEndpoint
    }
  }
}

extension ProfileKYCService: TargetType {
  var baseURL: URL {
    let baseString = KNAppTracker.getKyberProfileBaseString()
    return URL(string: "\(baseString)/api")!
  }

  var path: String { return self.apiPath }
  var method: Moya.Method { return .post }
  var task: Task {
    switch self {
    case .personalInfo(let accessToken, let firstName, let lastName, let gender, let dob, let nationality, let country, let wallets):
      let arrJSON: String = {
        if wallets.isEmpty { return "[]" }
        var string = "["
        for id in 0..<wallets.count {
          string += "{\"label\": \"\(wallets[id].0)\", \"address\":\"\(wallets[id].1)\"}"
          if id < wallets.count - 1 {
            string += ","
          }
        }
        string += "]"
        return string
      }()
      let json: JSONDictionary = [
        "access_token": accessToken,
        "first_name": firstName,
        "last_name": lastName,
        "gender": gender,
        "dob": dob,
        "nationality": nationality,
        "country": country,
        "wallets": arrJSON,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .identityInfo(let accessToken, let documentType, let documentID, let docImage, let docHoldingImage):
      let json: JSONDictionary = [
        "access_token": accessToken,
        "document_type": documentType,
        "document_id": documentID,
        "photo_identity_doc": "data:image/jpeg;base64,\(docImage.base64EncodedString())",
        "photo_selfie": "data:image/jpeg;base64,\(docHoldingImage.base64EncodedString())",
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .submitKYC(let accessToken):
      let json: JSONDictionary = ["access_token": accessToken]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .userWallets(let accessToken):
      let json: JSONDictionary = ["access_token": accessToken]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .checkWalletExist(let accessToken, let wallet):
      let json: JSONDictionary = [
        "access_token": accessToken,
        "wallet": wallet,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    }
  }

  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    return [
      "content-type": "application/json",
      "client": Bundle.main.bundleIdentifier ?? "",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}
