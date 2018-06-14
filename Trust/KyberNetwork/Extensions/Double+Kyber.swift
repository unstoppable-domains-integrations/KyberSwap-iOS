// Copyright SIX DAY LLC. All rights reserved.

import Foundation

extension Double {
  func displayUSD() -> String {
    return self.display()
  }

  func display(minFractionDigits: Int = 0, maxFractionDigits: Int = 2, minIntegerDigits: Int = 1) -> String {
    let numberFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.maximumFractionDigits = maxFractionDigits
      formatter.minimumFractionDigits = minFractionDigits
      formatter.minimumIntegerDigits = minIntegerDigits
      return formatter
    }()
    return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
  }
}
