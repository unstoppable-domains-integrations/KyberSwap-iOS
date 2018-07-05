// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNLandingPageViewControllerDelegate: class {
  func landingPageCreateWalletPressed(sender: KNLandingPageViewController)
  func landingPageImportWalletPressed(sender: KNLandingPageViewController)
  func landingPageTermAndConditionPressed(sender: KNLandingPageViewController)
}

class KNLandingPageViewController: KNBaseViewController {

  weak var delegate: KNLandingPageViewControllerDelegate?

  @IBOutlet weak var createWalletButton: UIButton!
  @IBOutlet weak var importWalletButton: UIButton!
  @IBOutlet weak var termAndConditionButton: UIButton!

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.createWalletButton.rounded(color: .clear, width: 0, radius: 4.0)
    self.importWalletButton.rounded(color: .clear, width: 0, radius: 4.0)
  }

  @IBAction func createWalletButtonPressed(_ sender: Any) {
    self.delegate?.landingPageCreateWalletPressed(sender: self)
  }

  @IBAction func importWalletButtonPressed(_ sender: Any) {
    self.delegate?.landingPageImportWalletPressed(sender: self)
  }

  @IBAction func termAndConditionButtonPressed(_ sender: Any) {
    self.delegate?.landingPageTermAndConditionPressed(sender: self)
  }

  @IBAction func debugPressed(_ sender: Any) {
    let debugVC = KNDebugMenuViewController()
    self.present(debugVC, animated: true, completion: nil)
  }
}
