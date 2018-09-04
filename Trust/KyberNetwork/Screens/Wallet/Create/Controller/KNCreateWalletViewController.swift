// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNCreateWalletViewEvent {
  case back
  case next(name: String)
}

protocol KNCreateWalletViewControllerDelegate: class {
  func createWalletViewController(_ controller: KNCreateWalletViewController, run event: KNCreateWalletViewEvent)
}

class KNCreateWalletViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var createWalletButton: UIButton!

  weak var delegate: KNCreateWalletViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.walletNameTextField.becomeFirstResponder()
  }

  fileprivate func setupUI() {
    let style = KNAppStyleType.current
    self.view.backgroundColor = style.createWalletBackgroundColor
    self.headerContainerView.backgroundColor = style.walletFlowHeaderColor
    self.navTitleLabel.text = "Create your Wallet".toBeLocalised()
    self.createWalletButton.rounded(radius: style.buttonRadius(for: self.createWalletButton.frame.height))
    self.createWalletButton.backgroundColor = style.createWalletButtonEnabledColor
    self.createWalletButton.setTitle(
      style.buttonTitle(with: "Confirm".toBeLocalised()),
      for: .normal
    )
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.createWalletViewController(self, run: .back)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.createWalletViewController(self, run: .back)
    }
  }

  @IBAction func createWalletButtonPressed(_ sender: Any) {
    let name: String = {
      if let text = self.walletNameTextField.text, !text.isEmpty { return text }
      return "Untitled"
    }()
    self.delegate?.createWalletViewController(self, run: .next(name: name))
  }
}
