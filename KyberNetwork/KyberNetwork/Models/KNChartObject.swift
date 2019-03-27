// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNChartObject: Object {

  @objc var time: Int64 = 0
  @objc var open: Double = 0.0
  @objc var close: Double = 0.0
  @objc var low: Double = 0.0
  @objc var high: Double = 0.0
  @objc var symbol: String = ""
  @objc var resolution: String = ""

  @objc var compoundKey: String = ""

  convenience init(
    time: Int64,
    open: Double,
    close: Double,
    low: Double,
    high: Double,
    symbol: String,
    resolution: String
    ) {
    self.init()
    self.time = time
    self.open = open
    self.close = close
    self.low = low
    self.high = high
    self.symbol = symbol
    self.resolution = resolution
    self.compoundKey = "\(symbol)-\(resolution)-\(time)"
  }

  var date: Date {
    return Date(timeIntervalSince1970: Double(time))
  }

  override static func primaryKey() -> String {
    return "compoundKey"
  }
}

extension KNChartObject {

  static func objects(from data: JSONDictionary, symbol: String, resolution: String) -> [KNChartObject] {
    guard let times = data["t"] as? [Int64],
      let opens = data["o"] as? [Double],
      let closes = data["c"] as? [Double],
      let lows = data["l"] as? [Double],
      let highs = data["h"] as? [Double] else {
        return []
    }
    var results: [KNChartObject] = []
    for id in 0..<times.count {
      let object: KNChartObject = {
        return KNChartObject(
          time: times[id],
          open: opens[id],
          close: closes[id],
          low: lows[id],
          high: highs[id],
          symbol: symbol,
          resolution: resolution
        )
      }()
      results.append(object)
    }
    return results
  }
}
