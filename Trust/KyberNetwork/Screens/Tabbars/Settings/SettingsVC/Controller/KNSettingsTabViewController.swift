// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNSettingsTabViewEvent {
  case manageWallet
  case contact
  case support
  case changePIN
  case rateMyApp
  case about
  case shareWithFriends
  case telegram
  case github
  case twitter
  case facebook
  case medium
  case reddit
  case linkedIn
  case google
}

protocol KNSettingsTabViewControllerDelegate: class {
  func settingsTabViewController(_ controller: KNSettingsTabViewController, run event: KNSettingsTabViewEvent)
}

class KNSettingsTabViewController: KNBaseViewController {

  weak var delegate: KNSettingsTabViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func manageWalletButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .manageWallet)
  }

  @IBAction func contactButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .contact)
  }

  @IBAction func supportButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .support)
  }

  @IBAction func changePasscodeButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .changePIN)
  }

  @IBAction func rateMyAppButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .rateMyApp)
  }

  @IBAction func aboutButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .about)
  }

  @IBAction func shareWithFriendButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .shareWithFriends)
  }

  @IBAction func telegramButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .telegram)
  }

  @IBAction func githubButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .github)
  }

  @IBAction func twitterButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .twitter)
  }

  @IBAction func facebookButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .facebook)
  }

  @IBAction func mediumButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .medium)
  }

  @IBAction func redditButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .reddit)
  }

  @IBAction func linkedInButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .linkedIn)
  }

  @IBAction func googleButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .google)
  }
}
