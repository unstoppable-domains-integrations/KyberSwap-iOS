// Copyright SIX DAY LLC. All rights reserved.

import Moya

enum KNCoinMarketCapService {
  case loadCoinTickers(limit: Int, currency: String)
  case loadCoinTicker(id: String, currency: String)
}

extension KNCoinMarketCapService: TargetType {
  var baseURL: URL {
    switch self {
    case .loadCoinTickers(let limit, let currency):
      let base = "https://api.coinmarketcap.com/v1/ticker/?limit=\(limit)&convert=\(currency)"
      return URL(string: base)!
    case .loadCoinTicker(let id, let currency):
      let base = "https://api.coinmarketcap.com/v1/ticker/\(id)/?convert=\(currency)"
      return URL(string: base)!
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
    ]
  }
}
