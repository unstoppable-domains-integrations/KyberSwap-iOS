// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNLandingPageViewEvent {
  case openCreateWallet
  case openImportWallet
  case openTermAndCondition
}

protocol KNLandingPageViewControllerDelegate: class {
  func landinagePageViewController(_ controller: KNLandingPageViewController, run event: KNLandingPageViewEvent)
}

class KNLandingPageViewController: KNBaseViewController {

  weak var delegate: KNLandingPageViewControllerDelegate?

  @IBOutlet weak var welcomeScreenCollectionView: KNWelcomeScreenCollectionView!
  @IBOutlet weak var debugButton: UIButton!
  @IBOutlet weak var createWalletButton: UIButton!
  @IBOutlet weak var importWalletButton: UIButton!
  @IBOutlet weak var termAndConditionButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    let style = KNAppStyleType.current
    self.view.applyGradient(with: UIColor.Kyber.backgroundColors)

    self.createWalletButton.backgroundColor = style.landingCreateWalletBackgroundColor
    self.createWalletButton.setTitleColor(
      UIColor(red: 250, green: 107, blue: 100),
      for: .normal
    )
    self.createWalletButton.setTitle(
      NSLocalizedString("create.wallet", value: "Create Wallet", comment: ""),
      for: .normal
    )
    self.importWalletButton.backgroundColor = .clear
    self.importWalletButton.setTitleColor(
      .white,
      for: .normal
    )
    self.importWalletButton.setTitle(
      NSLocalizedString("import.wallet", value: "Import Wallet", comment: ""),
      for: .normal
    )
    self.importWalletButton.addTextSpacing()

    let radius = style.buttonRadius(for: self.createWalletButton.frame.height)
    self.createWalletButton.rounded(radius: radius)
    self.createWalletButton.addTextSpacing()
    self.importWalletButton.rounded(color: .white, width: 1.0, radius: radius)
    self.termAndConditionButton.setTitle(
      NSLocalizedString("terms.and.conditions", value: "Terms and Conditions", comment: ""),
      for: .normal
    )
    self.termAndConditionButton.setTitleColor(.white, for: .normal)
    self.termAndConditionButton.addTextSpacing()
    self.debugButton.isHidden = false
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.view.removeSublayer(at: 0)
    self.view.applyGradient(with: UIColor.Kyber.backgroundColors)
  }

  @IBAction func createWalletButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openCreateWallet)
  }

  @IBAction func importWalletButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openImportWallet)
  }

  @IBAction func termAndConditionButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openTermAndCondition)
  }

  @IBAction func debugPressed(_ sender: Any) {
    let debugVC = KNDebugMenuViewController()
    self.present(debugVC, animated: true, completion: nil)
  }
}
