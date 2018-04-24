// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNPasscodeCoordinator: Coordinator {

  let window: UIWindow
  let type: KNPasscodeViewType
  var coordinators: [Coordinator] = []

  init(type: KNPasscodeViewType) {
    self.window = UIWindow()
    self.type = type
  }

  func start() {
    self.window.rootViewController = KNPasscodeViewController(viewType: self.type, delegate: self)
    self.window.windowLevel = UIWindowLevelStatusBar + 2.0
    self.window.makeKeyAndVisible()
    self.window.isHidden = false
  }

  func stop() {
    self.window.isHidden = true
  }
}

extension KNPasscodeCoordinator: KNPasscodeViewControllerDelegate {
  func passcodeViewControllerDidSuccessEvaluatePolicyWithBio() {
    self.stop()
  }

  func passcodeViewControllerDidCancel() {
    self.stop()
  }

  func passcodeViewControllerDidCreateNewPasscode(_ passcode: String) {
    self.stop()
  }

  func passcodeViewControllerDidEnterPasscode(_ passcode: String) {
    self.stop()
  }
}
