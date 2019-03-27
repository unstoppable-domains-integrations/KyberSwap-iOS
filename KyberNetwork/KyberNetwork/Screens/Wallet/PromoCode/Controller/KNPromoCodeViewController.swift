// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Crashlytics

protocol KNPromoCodeViewControllerDelegate: class {
  func promoCodeViewControllerDidClose()
  func promoCodeViewController(_ controller: KNPromoCodeViewController, promoCode: String, name: String)
}

class KNPromoCodeViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var yourPromoCodeTextLabel: UILabel!
  @IBOutlet weak var enterPromoCodeTextField: UITextField!
  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var applyButton: UIButton!

  weak var delegate: KNPromoCodeViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = NSLocalizedString("kybercode", value: "KyberCode", comment: "")

    self.yourPromoCodeTextLabel.text = NSLocalizedString("your.kybercode", value: "Your KyberCode", comment: "")
    self.enterPromoCodeTextField.placeholder = NSLocalizedString("enter.your.kybercode", value: "Enter your KyberCode", comment: "")
    self.walletNameTextField.placeholder = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")

    self.applyButton.setTitle(NSLocalizedString("apply", value: "Apply", comment: ""), for: .normal)
    self.applyButton.rounded(radius: KNAppStyleType.current.buttonRadius(for: self.applyButton.frame.height))
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.enterPromoCodeTextField.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  func resetUI() {
    self.enterPromoCodeTextField.text = ""
    self.walletNameTextField.text = ""
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.promoCodeViewControllerDidClose()
  }

  @IBAction func applyButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "kybercode", customAttributes: ["type": "apply_button"])
    let promoCode = self.enterPromoCodeTextField.text ?? ""
    guard !promoCode.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("kybercode.is.empty", value: "KyberCode is empty", comment: ""),
        time: 1.5
      )
      return
    }
    let name: String = {
      let name = self.walletNameTextField.text ?? ""
      return name.isEmpty ? "Untitled" : name
    }()
    self.delegate?.promoCodeViewController(self, promoCode: promoCode, name: name)
  }
}
