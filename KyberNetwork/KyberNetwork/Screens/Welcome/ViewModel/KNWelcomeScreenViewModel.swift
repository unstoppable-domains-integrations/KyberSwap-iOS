// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNWelcomeScreenViewModel {

  public struct KNWelcomeData {
    let icon: String
    let title: String
    let subtitle: String
    let position: Int

    init(dict: JSONDictionary) {
      icon = dict["icon"] as? String ?? ""
      title = dict["title"] as? String ?? ""
      subtitle = dict["subtitle"] as? String ?? ""
      position = dict["position"] as? Int ?? 0
    }
  }

  let dataList: [KNWelcomeData]

  init() {
    if let json: JSONDictionary = KNJSONLoaderUtil.jsonDataFromFile(with: "welcome_screen_data") {
      let data = json["data"] as? [JSONDictionary] ?? []
      self.dataList = data.map({ return KNWelcomeData(dict: $0) })
    } else {
      self.dataList = []
    }
  }

  var numberRows: Int { return self.dataList.count }

  func welcomeData(at row: Int) -> KNWelcomeData {
    return self.dataList[row]
  }
}
