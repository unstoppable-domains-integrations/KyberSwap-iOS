// Copyright SIX DAY LLC. All rights reserved.

import Moya

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
}

extension KyberGOService: TargetType {
  var baseURL: URL {
    return URL(string: "https://kyber.mangcut.vn/api/ieos")!
  }

  var path: String { return "" }
  var method: Moya.Method { return .get }
  var task: Task { return .requestPlain }
  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    return [
      "content-type": "application/json",
      "client": Bundle.main.bundleIdentifier ?? "",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}
