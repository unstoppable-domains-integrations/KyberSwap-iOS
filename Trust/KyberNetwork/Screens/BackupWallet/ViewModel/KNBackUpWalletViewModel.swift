// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNBackUpWalletViewModel {
  let seeds: [String]

  let numberWords: Int = 4
  fileprivate let maxWords: Int = 12
  fileprivate(set) var currentWordIndex: Int = 0

  init(seeds: [String]) {
    self.seeds = seeds
  }

  func attributedString(for id: Int) -> NSAttributedString {
    let wordID: Int = id + self.currentWordIndex + 1
    let word: String = self.seeds[wordID - 1]
    let attributedString: NSMutableAttributedString = {
      let idAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(hex: "04140b"),
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17),
      ]
      let wordAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(hex: "f89f50"),
      ]
      let attributedString = NSMutableAttributedString()
      attributedString.append(NSAttributedString(string: "\(wordID)", attributes: idAttributes))
      attributedString.append(NSAttributedString(string: " \(word)", attributes: wordAttributes))
      return attributedString
    }()
    return attributedString
  }

  func updateNextBackUpWords() -> Bool {
    self.currentWordIndex += self.numberWords
    return self.currentWordIndex >= self.maxWords - 1
  }

  var backUpWalletText: String {
    return "Backup Your Wallet".toBeLocalised()
  }

  var titleText: String {
    return self.currentWordIndex == 0 ? "Paper Only".toBeLocalised() : ""
  }

  var descriptionAttributedText: NSMutableAttributedString {
    if self.currentWordIndex > 0 { return NSMutableAttributedString() }
    let regularttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular),
    ]
    let boldAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.bold),
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "We will give you a list of 12 random words. Please ".toBeLocalised(), attributes: regularttributes))
    attributedString.append(NSAttributedString(string: "write them down on paper ".toBeLocalised(), attributes: boldAttributes))
    attributedString.append(NSAttributedString(string: "and keep safe.\n\nThis paper key is ".toBeLocalised(), attributes: regularttributes))
    attributedString.append(NSAttributedString(string: "the only way ".toBeLocalised(), attributes: boldAttributes))
    attributedString.append(NSAttributedString(string: "to restore your Kyber Wallet if you lose your phone or forget your password.".toBeLocalised(), attributes: regularttributes))
    return attributedString
  }

  var writeDownWordsText: String {
    return "Write down the words from \(self.currentWordIndex + 1)-\(self.currentWordIndex + self.numberWords)".toBeLocalised()
  }

  var wroteDownButtonTitle: String {
    return "I wrote down the words from \(self.currentWordIndex + 1) to \(self.currentWordIndex + self.numberWords)".toBeLocalised()
  }
}
