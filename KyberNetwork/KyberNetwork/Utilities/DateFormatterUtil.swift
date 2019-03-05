// Copyright SIX DAY LLC. All rights reserved.

import Foundation

class DateFormatterUtil {

  static let shared = DateFormatterUtil()

  lazy var priceAlertAPIFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter
  }()
}
