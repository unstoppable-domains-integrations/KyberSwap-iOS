//
//  UILabel+Kyber.swift
//  KyberNetwork
//
//  Created by Le Xuan Manh on 27/12/2018.
//

import UIKit

extension UILabel {
  func addLetterSpacing(value: Double = 0) {
    if let labelText = text, !labelText.isEmpty {
      let attributedString = NSMutableAttributedString(string: labelText)
      attributedString.addAttribute(NSAttributedStringKey.kern, value: value, range: NSRange(location: 0, length: labelText.count))
      attributedText = attributedString
    }
  }
}
