// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNBackUpWalletState {
  case backup
  case testBackup
}

class KNBackUpWalletViewModel {
  let seeds: [String]
  var state: KNBackUpWalletState = .backup
  var firstWordID: Int
  var secondWordID: Int

  let numberWords: Int = 4
  fileprivate let maxWords: Int = 12
  fileprivate(set) var currentWordIndex: Int = 0

  init(seeds: [String]) {
    self.seeds = seeds
    self.firstWordID = Int(arc4random() % 12)
    self.secondWordID = (self.firstWordID + Int(arc4random() % 11 + 1)) % 12
  }

  lazy var defaultTime: Int = {
    return isDebug ? 3 : 15
  }()

  func attributedString(for id: Int) -> NSAttributedString {
    let wordID: Int = id + self.currentWordIndex + 1
    if wordID > self.seeds.count { return NSMutableAttributedString() }
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

  func updateNextBackUpWords() {
    self.currentWordIndex += self.numberWords
    if self.currentWordIndex >= self.maxWords - 1 {
      self.state = .testBackup
    } else {
      self.state = .backup
    }
  }

  lazy var backUpWalletText: String = {
    return "Backup Your Wallet".toBeLocalised()
  }()

  var backUpTitleText: String {
    return self.currentWordIndex == 0 ? "Paper Only".toBeLocalised() : ""
  }

  var backUpDescAttributedString: NSMutableAttributedString {
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

  lazy var testingBackUpText: String = {
    return "Test your Backup".toBeLocalised()
  }()

  lazy var testingBackUpDescText: NSMutableAttributedString = {
    let regularttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular),
      ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(
      string: "To make sure you have written down all of your backup words. Please enter the following.".toBeLocalised(),
      attributes: regularttributes
    ))
    return attributedString
  }()

  lazy var completeButtonText: String = {
    return "Complete".toBeLocalised().uppercased()
  }()

  var iconName: String {
    return self.state == .backup ? "back_up_icon" : "test_back_up_icon"
  }

  var headerText: String {
    return self.state == .backup ? self.backUpWalletText : self.testingBackUpText
  }

  var titleText: String {
    return self.state == .backup ? self.backUpTitleText : ""
  }

  var descriptionAttributedText: NSAttributedString {
    return self.state == .backup ? self.backUpDescAttributedString : self.testingBackUpDescText
  }

  var isWriteDownWordsLabelHidden: Bool {
    return self.state == .testBackup
  }

  var isListWordsLabelsHidden: Bool {
    return self.state == .testBackup
  }

  var isWroteDownButtonHidden: Bool {
    return self.state == .testBackup
  }

  var isTestWordsTextFieldHidden: Bool {
    return self.state == .backup
  }

  var firstWordTextFieldPlaceholder: String {
    return "Word #\(self.firstWordID)".toBeLocalised()
  }

  var secondWordTextFieldPlaceholder: String {
    return "Word #\(self.secondWordID)".toBeLocalised()
  }

  var isCompleteButtonHidden: Bool {
    return self.state == .backup
  }

  func isTestPassed(firstWord: String, secondWord: String) -> Bool {
    return self.seeds[self.firstWordID - 1] == firstWord && self.seeds[self.secondWordID - 1] == secondWord
  }
}
