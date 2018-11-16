// Copyright SIX DAY LLC. All rights reserved.

import Foundation

typealias JSONDictionary = [String: Any]

class KNJSONLoaderUtil {

  static let shared = KNJSONLoaderUtil()

  init() {}

  static func loadListSupportedTokensFromJSONFile() -> [TokenObject] {
    let configFileName = KNEnvironment.default.configFileName
    guard let json = KNJSONLoaderUtil.jsonDataFromFile(with: configFileName) else { return [] }
    guard let tokensJSON = json["tokens"] as? JSONDictionary else { return [] }
    let tokens = tokensJSON.values.map({ return TokenObject(localDict: $0 as? JSONDictionary ?? [:]) })
    return tokens
  }

  static func jsonDataFromFile(with name: String) -> JSONDictionary? {
    guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
      print("---> Error: File not found with name \(name)")
      return nil
    }
    let urlPath = URL(fileURLWithPath: path)
    var data: Data?
    do {
      data = try Data(contentsOf: urlPath)
    } catch let error {
      print("---> Error: Get data from file path \(urlPath.absoluteString) failed with error \(error.localizedDescription)")
      return nil
    }
    guard let jsonData = data else {
      print("---> Error: Can not cast data from file \(name) to json")
      return nil
    }
    do {
      let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
      // TODO: Data might be an array
      if let objc = json as? JSONDictionary { return objc }
    } catch let error {
      print("---> Error: Cast json from file path \(urlPath.absoluteString) failed with error \(error.localizedDescription)")
      return nil
    }
    return nil
  }
}
