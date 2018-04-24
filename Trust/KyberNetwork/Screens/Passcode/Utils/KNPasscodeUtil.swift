// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import KeychainSwift
import SAMKeychain

class KNPasscodeUtil {

  private let kMaxNumberAttempts: Int = 5

  private let kServiceKey: String = "kybernetworkwallet.authentication"
  private let kAccountKey: String = "kybernetworkwallet.account"
  static private let kKeychainPrefix: String = "kybernetworkwallet"
  private let kNumberAttempts: String = "numberAttempts"
  private let kMaxAttemptTime: String = "maxAttemptTime"

  let keychain: KeychainSwift = KeychainSwift(keyPrefix: kKeychainPrefix)

  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
  }()

  static let shared = KNPasscodeUtil()

  // MARK: Passcode
  func isPasscodeSet() -> Bool {
    return self.currentPasscode() != nil
  }

  func currentPasscode() -> String? {
    return SAMKeychain.password(forService: kServiceKey, account: kAccountKey)
  }

  @discardableResult
  func setNewPasscode(_ passcode: String) -> Bool {
    return SAMKeychain.setPassword(passcode, forService: kServiceKey, account: kAccountKey)
  }

  @discardableResult
  func deletePasscode() -> Bool {
    return SAMKeychain.deletePassword(forService: kServiceKey, account: kAccountKey)
  }

  func currentNumberAttempts() -> Int {
    guard let attempts = self.keychain.get(kNumberAttempts) else { return 0 }
    return Int(attempts) ?? 0
  }

  func numberAttemptsLeft() -> Int {
    return kMaxNumberAttempts - self.currentNumberAttempts()
  }

  func isExceedNumberAttempt() -> Bool {
    return self.currentNumberAttempts() == kMaxNumberAttempts
  }

  @discardableResult
  func recordNewAttempt() -> Bool {
    let numberAttempts = self.currentNumberAttempts() + 1
    return self.keychain.set(String(numberAttempts), forKey: kNumberAttempts)
  }

  @discardableResult
  func deleteNumberAttempts() -> Bool {
    return self.keychain.delete(kNumberAttempts)
  }

  func currentMaxAttemptTime() -> Date? {
    guard let maxAttemptTime = self.keychain.get(kMaxAttemptTime) else { return nil }
    return self.dateFormatter.date(from: maxAttemptTime)
  }

  // Time in second to allow user tries again
  func timeToAllowNewAttempt() -> Int {
    guard let date = self.currentMaxAttemptTime() else { return 0 }
    let timePassed = floor(Date().timeIntervalSince(date))
    return max(0, 60 - Int(timePassed))
  }

  func shouldAllowNewAttempts() -> Bool {
    return self.timeToAllowNewAttempt() == 0
  }

  @discardableResult
  func recordNewMaxAttemptTime() -> Bool {
    let time = self.dateFormatter.string(from: Date())
    return self.keychain.set(time, forKey: kMaxAttemptTime)
  }

  @discardableResult
  func deleteCurrentMaxAttemptTime() -> Bool {
    return self.keychain.delete(kMaxAttemptTime)
  }
}
