// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KGOSignInViewEvent {
  case dismiss
  case signUp
  case forgotPassword
  case signIn(email: String, password: String)
}

protocol KGOSignInViewControllerDelegate: class {
  func kgoSignInViewController(_ controller: KGOSignInViewController, sendEvent event: KGOSignInViewEvent)
}

class KGOSignInViewController: KNBaseViewController {

  @IBOutlet weak var signInTitleLabel: UILabel!
  @IBOutlet weak var emailAddressLabel: UILabel!
  @IBOutlet weak var emailAddressTextField: UITextField!
  @IBOutlet weak var passwordLabel: UILabel!
  @IBOutlet weak var passwordTextField: UITextField!

  @IBOutlet weak var signUpButton: UIButton!
  @IBOutlet weak var fotgotPasswordButton: UIButton!
  @IBOutlet weak var signInButton: UIButton!

  weak var delegate: KGOSignInViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.signInButton.rounded(radius: 4.0)
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.delegate?.kgoSignInViewController(self, sendEvent: .dismiss)
  }

  @IBAction func signUpButtonPressed(_ sender: Any) {
    self.delegate?.kgoSignInViewController(self, sendEvent: .signUp)
  }

  @IBAction func forgotPasswordPressed(_ sender: Any) {
    self.delegate?.kgoSignInViewController(self, sendEvent: .forgotPassword)
  }

  @IBAction func signInButtonPressed(_ sender: Any) {
    guard let email = self.emailAddressTextField.text, let password = self.passwordTextField.text else {
      self.showWarningTopBannerMessage(with: "Invalid input", message: "Please check data again")
      return
    }
    self.delegate?.kgoSignInViewController(self, sendEvent: .signIn(email: email, password: password))
  }
}
