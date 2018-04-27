// Copyright SIX DAY LLC. All rights reserved.

import Moya

let apiKey = "7V3E6JSF7941JCB6448FNRI3FSH9HI7HYH"

enum KNEtherScanService {
  case getListTransactions(address: String, startBlock: Int, endBlock: Int, page: Int)
  case getListTokenTransactions(address: String, startBlock: Int, page: Int, sort: String)
}

extension KNEtherScanService: TargetType {
  var baseURL: URL {
    switch self {
    case .getListTransactions(let address, let startBlock, let endBlock, let page):
      return URL(string: "http://api.etherscan.io/api?module=account&action=txlist&address=\(address)&startblock=\(startBlock)&endblock=\(endBlock)&page=\(page)&sort=asc&apikey=\(apiKey)")!
    case .getListTokenTransactions(let address, let startBlock, let page, let sort):
      return URL(string: "http://api.etherscan.io/api?module=account&action=tokentx&address=0x63825c174ab367968ec60f061753d3bbd36a0d8f&page=\(page)&offset=200&startblock=\(startBlock)&sort=\(sort)&apikey=\(apiKey)")!
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
