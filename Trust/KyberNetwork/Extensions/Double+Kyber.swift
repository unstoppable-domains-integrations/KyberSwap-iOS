// Copyright SIX DAY LLC. All rights reserved.

import Foundation

extension Double {
  func displayUSD() -> String {
    let numberFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.maximumFractionDigits = 2
      formatter.minimumFractionDigits = 0
      formatter.minimumIntegerDigits = 1
      return formatter
    }()
    return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
  }
}
