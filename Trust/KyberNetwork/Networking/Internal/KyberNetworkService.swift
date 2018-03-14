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
      "Content-type": "application/json",
      "client": Bundle.main.bundleIdentifier ?? "",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}
