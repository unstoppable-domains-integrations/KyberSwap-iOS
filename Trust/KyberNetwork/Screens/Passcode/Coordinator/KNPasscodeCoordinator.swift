// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNPasscodeCoordinator: NSObject, Coordinator {

  let window: UIWindow = UIWindow()
  let type: KNPasscodeViewType
  var coordinators: [Coordinator] = []

  lazy var passcodeViewController: KNPasscodeViewController = {
    let controller = KNPasscodeViewController(viewType: self.type, delegate: self)
    controller.loadViewIfNeeded()
    return controller
  }()

  init(type: KNPasscodeViewType) {
    self.type = type
    super.init()
    self.window.windowLevel = UIWindowLevelStatusBar + 1.0
    self.window.rootViewController = self.passcodeViewController
    self.window.isHidden = true
  }

  func start() {
    if KNPasscodeUtil.shared.currentPasscode() == nil { return }
    DispatchQueue.main.async {
      self.passcodeViewController.resetUI()
      self.window.makeKeyAndVisible()
      self.window.isHidden = false
      if self.type == .authenticate {
        self.passcodeViewController.showBioAuthenticationIfNeeded()
      }
    }
  }

  func stop() {
    DispatchQueue.main.async {
      self.window.isHidden = true
    }
  }
}

extension KNPasscodeCoordinator: KNPasscodeViewControllerDelegate {
  // Authentication
  func passcodeViewControllerDidSuccessEvaluatePolicyWithBio() {
    KNPasscodeUtil.shared.deleteNumberAttempts()
    KNPasscodeUtil.shared.deleteCurrentMaxAttemptTime()
    self.stop()
  }

  func passcodeViewControllerDidEnterPasscode(_ passcode: String) {
    guard let currentPasscode = KNPasscodeUtil.shared.currentPasscode() else {
      self.stop()
      return
    }
    if currentPasscode == passcode {
      KNPasscodeUtil.shared.deleteNumberAttempts()
      KNPasscodeUtil.shared.deleteCurrentMaxAttemptTime()
      self.stop()
    } else {
      KNPasscodeUtil.shared.recordNewAttempt()
      if KNPasscodeUtil.shared.numberAttemptsLeft() == 0 {
        KNPasscodeUtil.shared.recordNewMaxAttemptTime()
      }
      self.passcodeViewController.userDidTypeWrongPasscode()
    }
  }

  // Create passcode
  func passcodeViewControllerDidCancel() {
    self.stop()
  }

  func passcodeViewControllerDidCreateNewPasscode(_ passcode: String) {
    KNPasscodeUtil.shared.setNewPasscode(passcode)
  }
}
