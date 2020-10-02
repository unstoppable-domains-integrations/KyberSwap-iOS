// Copyright SIX DAY LLC. All rights reserved.

import WidgetKit

struct WidgetContent: Codable, TimelineEntry {
  var date = Date()
  let usdPrice: Double
  let change24h: Double
}
