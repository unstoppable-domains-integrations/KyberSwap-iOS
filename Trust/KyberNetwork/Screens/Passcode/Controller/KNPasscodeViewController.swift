// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import LocalAuthentication

protocol KNPasscodeViewControllerDelegate: class {
  func passcodeViewControllerDidSuccessEvaluatePolicyWithBio()
  func passcodeViewControllerDidEnterPasscode(_ passcode: String)
  func passcodeViewControllerDidCreateNewPasscode(_ passcode: String)
  func passcodeViewControllerDidCancel()
}

enum KNPasscodeViewType {
  // view to set new passcode
  case setPasscode
  // view to authenticate
  case authenticate
}

class KNPasscodeViewController: KNBaseViewController {
  fileprivate let viewType: KNPasscodeViewType
  fileprivate weak var delegate: KNPasscodeViewControllerDelegate?

  fileprivate var currentPasscode = ""
  fileprivate var firstPasscode: String?

  fileprivate var timer: Timer?

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var errorLabel: UILabel!

  @IBOutlet weak var passcodeContainerView: UIView!
  @IBOutlet var passcodeViews: [UIView]!

  @IBOutlet var digitButtons: [UIButton]!
  @IBOutlet weak var actionButton: UIButton!

  init(viewType: KNPasscodeViewType, delegate: KNPasscodeViewControllerDelegate?) {
    self.viewType = viewType
    self.delegate = delegate
    super.init(nibName: KNPasscodeViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUI()
    if self.viewType == .authenticate {
      if KNPasscodeUtil.shared.numberAttemptsLeft() == 0 {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
          if KNPasscodeUtil.shared.timeToAllowNewAttempt() == 0 {
            KNPasscodeUtil.shared.deleteNumberAttempts()
            KNPasscodeUtil.shared.deleteCurrentMaxAttemptTime()
            self.timer?.invalidate()
          }
          self.updateUI()
        })
      }
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.timer?.invalidate()
    self.timer = nil
  }

  fileprivate func setupUI() {
    self.passcodeViews.forEach({ $0.rounded(color: .white, width: 1.0, radius: $0.frame.width / 2.0) })
    self.digitButtons.forEach({ $0.rounded(color: .white, width: 1.0, radius: $0.frame.width / 2.0) })
    self.actionButton.setTitle(self.actionButtonTitle, for: .normal)
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.titleLabel.text = self.titleText
    self.errorLabel.text = self.errorText
    self.passcodeViews.forEach({ $0.backgroundColor = $0.tag < self.currentPasscode.count ? .white : .clear })
    self.actionButton.setTitle(self.actionButtonTitle, for: .normal)
    self.view.layoutIfNeeded()
  }

  func showBioAuthenticationIfNeeded() {
    if self.viewType == .setPasscode { return }
    if KNPasscodeUtil.shared.timeToAllowNewAttempt() > 0 { return }
    var error: NSError?
    let context = LAContext()
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      return
    }
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Use touchID/faceID to secure your account".toBeLocalised()) { [weak self] (success, error) in
      guard let `self` = self else { return }
      DispatchQueue.main.async {
        if success {
          self.delegate?.passcodeViewControllerDidSuccessEvaluatePolicyWithBio()
        } else {
          guard let error = error else { return }
          guard let message = self.errorMessageForLAErrorCode(error.code) else {
            // User cancelled using bio
            return
          }
          let alert = UIAlertController(title: "Try Again".toBeLocalised(), message: message, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Try Again".toBeLocalised(), style: .default, handler: { _ in
            self.showBioAuthenticationIfNeeded()
          }))
          alert.addAction(UIAlertAction(title: "Enter passcode".toBeLocalised(), style: .default, handler: nil))
          self.present(alert, animated: true, completion: nil)
        }
      }
    }
  }

  func resetUI() {
    self.currentPasscode = ""
    self.firstPasscode = nil
    self.updateUI()
  }

  func userDidTypeWrongPasscode() {
    // shake passcode view
    self.currentPasscode = ""
    self.updateUI()

    let keypath = "position"
    let animation = CABasicAnimation(keyPath: keypath)
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: self.passcodeContainerView.center.x - 10, y: self.passcodeContainerView.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: self.passcodeContainerView.center.x + 10, y: self.passcodeContainerView.center.y))
    self.passcodeContainerView.layer.add(animation, forKey: keypath)

    if KNPasscodeUtil.shared.numberAttemptsLeft() == 0 {
      self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
        if KNPasscodeUtil.shared.timeToAllowNewAttempt() == 0 {
          KNPasscodeUtil.shared.deleteNumberAttempts()
          KNPasscodeUtil.shared.deleteCurrentMaxAttemptTime()
          self.timer?.invalidate()
        }
        self.updateUI()
      })
    }
  }

  @IBAction func digitButtonPressed(_ sender: UIButton) {
    if KNPasscodeUtil.shared.numberAttemptsLeft() == 0 { return }
    self.currentPasscode = "\(self.currentPasscode)\(sender.tag)"
    if self.currentPasscode.count == 6 {
      self.userDidEnterPasscode()
    }
    self.updateUI()
  }

  @IBAction func actionButtonPressed(_ sender: UIButton) {
    if !self.currentPasscode.isEmpty {
      self.currentPasscode = String(self.currentPasscode.prefix(self.currentPasscode.count - 1))
      self.updateUI()
    }
  }

  fileprivate func userDidEnterPasscode() {
    if self.viewType == .authenticate {
      self.delegate?.passcodeViewControllerDidEnterPasscode(self.currentPasscode)
    } else {
      guard let firstPass = self.firstPasscode else {
        self.firstPasscode = self.currentPasscode
        self.currentPasscode = ""
        return
      }
      if firstPass == self.currentPasscode {
        self.delegate?.passcodeViewControllerDidCreateNewPasscode(self.currentPasscode)
      } else {
        self.firstPasscode = nil
        self.currentPasscode = ""
        self.updateUI()
      }
    }
  }
}

extension KNPasscodeViewController {
  fileprivate var titleText: String {
    switch self.viewType {
    case .authenticate:
      return "Enter your PIN".toBeLocalised()
    case .setPasscode:
      if self.firstPasscode != nil {
        return "Repeat PIN".toBeLocalised()
      }
      return "Set PIN".toBeLocalised()
    }
  }

  fileprivate var errorText: String {
    if self.viewType == .setPasscode {
      if self.firstPasscode == nil {
        return "Your PIN is used to access your wallets".toBeLocalised()
      }
      return "Remember this code to access your wallets".toBeLocalised()
    }
    if KNPasscodeUtil.shared.currentNumberAttempts() == 0 { return "" }
    if KNPasscodeUtil.shared.isExceedNumberAttempt() {
      return "Too many attempts, please try in \(KNPasscodeUtil.shared.timeToAllowNewAttempt()) second(s).".toBeLocalised()
    }
    let numberAttemptsLeft = KNPasscodeUtil.shared.numberAttemptsLeft()
    return "You have \(numberAttemptsLeft) attempt(s).".toBeLocalised()
  }

  fileprivate var actionButtonTitle: String {
    if !self.currentPasscode.isEmpty { return "Delete".toBeLocalised() }
    return ""
  }

  func errorMessageForLAErrorCode(_ errorCode: Int ) -> String? {
    if #available(iOS 11.0, *) {
      switch errorCode {
      case LAError.biometryLockout.rawValue:
        return "Too many failed attempts. Please try to use passcode".toBeLocalised()
      case LAError.biometryNotAvailable.rawValue:
        return "TouchID/FaceID is not available on the device".toBeLocalised()
      default:
        break
      }
    }
    switch errorCode {
    case LAError.authenticationFailed.rawValue:
      return "Invalid authentication.".toBeLocalised()
    case LAError.passcodeNotSet.rawValue:
      return "PIN is not set on the device".toBeLocalised()
    case LAError.touchIDLockout.rawValue:
      return "Too many failed attempts. Please try to use passcode".toBeLocalised()
    case LAError.touchIDNotAvailable.rawValue:
      return "TouchID/FaceID is not available on the device".toBeLocalised()
    case LAError.appCancel.rawValue, LAError.userCancel.rawValue, LAError.userFallback.rawValue:
      return nil
    default:
      return "Something went wrong. Try to use PIN".toBeLocalised()
    }
  }
}
