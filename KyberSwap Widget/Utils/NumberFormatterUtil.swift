// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class NumberFormatterUtil: NSObject {

  static let shared = NumberFormatterUtil()

  lazy var priceFomatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.decimalSeparator = Locale.current.decimalSeparator ?? "."
    formatter.groupingSeparator = Locale.current.groupingSeparator ?? ","
    formatter.usesGroupingSeparator = true
    formatter.maximumFractionDigits = 9
    formatter.minimumFractionDigits = 0
    return formatter
  }()

  lazy var priceBigFomatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.decimalSeparator = Locale.current.decimalSeparator ?? "."
    formatter.groupingSeparator = Locale.current.groupingSeparator ?? ","
    formatter.usesGroupingSeparator = true
    formatter.maximumFractionDigits = 4
    formatter.minimumFractionDigits = 0
    return formatter
  }()

  lazy var changeFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.decimalSeparator = Locale.current.decimalSeparator ?? "."
    formatter.groupingSeparator = Locale.current.groupingSeparator ?? ","
    formatter.usesGroupingSeparator = true
    return formatter
  }()

  func displayChange(from change: Double) -> String {
    return self.changeFormatter.string(from: NSNumber(value: change)) ?? "0.00"
  }

  func displayPrice(from price: Double) -> String {
    if price > 1 {
      return self.priceBigFomatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
    guard let display = self.priceFomatter.string(from: NSNumber(value: price)) else {
      return "\(price)"
    }
    let separator: String = Locale.current.decimalSeparator ?? "."

    var string = display
    if let _ = string.firstIndex(of: separator[separator.startIndex]) { string = string + "0000" }
    var start = false
    var cnt = 0
    var index = string.startIndex
    for id in 0..<string.count {
      if string[index] == separator[separator.startIndex] {
        start = true
      } else if start {
        if cnt > 0 || string[index] != "0" { cnt += 1 }
        if cnt == 4 { return string.substring(to: id + 1) }
      }
      index = string.index(after: index)
    }
    if cnt == 0, let id = string.firstIndex(of: separator[separator.startIndex]) {
      index = string.index(id, offsetBy: 5)
      return String(string[..<index])
    }
    return string
  }
}
