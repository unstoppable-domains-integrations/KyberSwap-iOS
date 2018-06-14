// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KGOIEODetailsViewModel {

  var object: IEOObject
  let isFull: Bool
  var currentRate: BigInt?

  init(
    object: IEOObject,
    isFull: Bool = false
    ) {
    self.object = object
    self.isFull = isFull
  }

  var bannerURL: URL? { return URL(string: object.bannerShort) }
  var iconURL: URL? { return URL(string: object.icon) }
  var displayedName: String { return object.name }
  var displayedContent: String { return object.tagLine }

  lazy var endDaysAttributedString: NSAttributedString = {
    let attributedString = NSMutableAttributedString()
    let timeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium),
    ]
    let typeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "adb6ba"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular),
    ]
    let string: String = {
      if object.type == .past { return "ENDED" }
      return object.type == .active ? "ENDS" : "STARTS"
    }()
    //TODO
    attributedString.append(NSAttributedString(string: string, attributes: typeAttributes))
    let date: String = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd MMM"
      if object.type == .upcoming {
        return formatter.string(from: object.startDate)
      }
      return formatter.string(from: object.endDate)
    }()
    attributedString.append(NSAttributedString(string: "\n\(date)", attributes: timeAttributes))
    return attributedString
  }()

  var rateText: String {
    guard let rate = self.currentRate else {
      return "1 ETH = \(object.standardRate) \(object.tokenSymbol)"
    }
    let string = rate.shortString(decimals: object.tokenDecimals, maxFractionDigits: 4)
    return "1 ETH = \(string) \(object.tokenSymbol)"
  }

  var buyTokenButtonTitle: String {
    if self.object.progress == 1 { return "Solve Out" }
    return "Buy Tokens"
  }

  var buyTokenButtonBackgroundColor: UIColor {
    if self.object.progress == 1 { return UIColor(hex: "F89F50") }
    return UIColor(hex: "31CB9E")
  }

  var displayedDayAttributedString: NSAttributedString {
    return self.displayTimeAttributedString(time: self.displayedDayString, type: "days")
  }
  var displayedHourAttributedString: NSAttributedString {
    return self.displayTimeAttributedString(time: self.displayedHourString, type: "hours")
  }
  var displayedMinuteAttributedString: NSAttributedString {
    return self.displayTimeAttributedString(time: self.displayedMinuteString, type: "minutes")
  }
  var displayedSecondAttributedString: NSAttributedString {
    return self.displayTimeAttributedString(time: self.displayedSecondString, type: "seconds")
  }

  var displayedRaisedProgress: Float { return object.progress }
  var displayedRaisedAmount: String { return object.raisedText }
  var displayedRaisedPercent: String { return object.raisedPercent }

  var displayedDesc: String { return object.desc }

  var whitePaperAttributedText: NSAttributedString {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "adb6ba"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular),
      NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
    ]
    return NSAttributedString(
      string: "White paper",
      attributes: attributes
    )
  }

  fileprivate var timeInterval: TimeInterval {
    switch object.type {
    case .past: return 0.0
    case .active: return object.endDate.timeIntervalSince(Date())
    case .upcoming: return object.startDate.timeIntervalSince(Date())
    }
  }

  fileprivate var displayedDayString: String {
    return "\(Int(floor(timeInterval / (24.0 * 60.0 * 60.0))))"
  }

  fileprivate var displayedHourString: String {
    return "\((Int(floor(timeInterval)) % (24 * 60 * 60)) / (60 * 60))"
  }

  fileprivate var displayedMinuteString: String {
    return "\((Int(floor(timeInterval)) % (60 * 60)) / 60)"
  }

  fileprivate var displayedSecondString: String {
    return "\(Int(floor(timeInterval)) % 60)"
  }

  fileprivate func displayTimeAttributedString(time: String, type: String) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let timeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.medium),
    ]
    let typeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "adb6ba"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular),
    ]
    attributedString.append(NSAttributedString(string: time, attributes: timeAttributes))
    attributedString.append(NSAttributedString(string: "\n\(type)", attributes: typeAttributes))
    return attributedString
  }

  // MARK: Update
  func updateCurrentRate(_ rate: BigInt) {
    self.currentRate = rate
  }
}
