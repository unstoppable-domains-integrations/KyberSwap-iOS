// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

protocol KNImportPrivateKeyViewControllerDelegate: class {
  func importPrivateKeyViewControllerDidPressNext(sender: KNImportPrivateKeyViewController, privateKey: String, name: String?)
}

class KNImportPrivateKeyViewController: KNBaseViewController {

  weak var delegate: KNImportPrivateKeyViewControllerDelegate?

  private var isSecureText: Bool = true
  @IBOutlet weak var secureTextButton: UIButton!
  @IBOutlet weak var enterPrivateKeyTextLabel: UILabel!
  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var enterPrivateKeyTextField: UITextField!
  @IBOutlet weak var privateKeyNoteLabel: UILabel!

  @IBOutlet weak var nextButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.enterPrivateKeyTextLabel.text = "Your Private Key".toBeLocalised()
    self.enterPrivateKeyTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 0))
    self.enterPrivateKeyTextField.rightViewMode = .always
    self.enterPrivateKeyTextField.delegate = self

    self.privateKeyNoteLabel.text = "Private key has to be 64 characters".toBeLocalised()

    let style = KNAppStyleType.current
    self.nextButton.rounded(radius: style.buttonRadius(for: self.nextButton.frame.height))
    self.nextButton.setBackgroundColor(
      style.importWalletButtonDisabledColor,
      forState: .disabled
    )
    self.nextButton.setBackgroundColor(
      style.importWalletButtonEnabledColor,
      forState: .normal
    )
    self.nextButton.setTitle(
      style.buttonTitle(with: "Import Wallet".toBeLocalised()),
      for: .normal
    )

    self.resetUI()
  }

  func resetUI() {
    self.enterPrivateKeyTextField.text = ""
    self.walletNameTextField.text = ""
    self.isSecureText = true
    self.updateSecureTextEntry()

    self.updateNextButton()
  }

  fileprivate func updateSecureTextEntry() {
    let secureTextImage = UIImage(named: self.isSecureText ? "hide_secure_text" : "show_secure_text")
    self.secureTextButton.setImage(secureTextImage, for: .normal)
    self.enterPrivateKeyTextField.isSecureTextEntry = self.isSecureText
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = {
      if let text = self.enterPrivateKeyTextField.text, !text.isEmpty { return true }
      return false
    }()
    self.nextButton.isEnabled = enabled
  }

  @IBAction func qrCodeButtonPressed(_ sender: Any) {
    let qrcodeReader = QRCodeReaderViewController()
    qrcodeReader.delegate = self
    self.parent?.present(qrcodeReader, animated: true, completion: nil)
  }

  @IBAction func secureTextButtonPressed(_ sender: Any) {
    self.isSecureText = !self.isSecureText
    self.updateSecureTextEntry()
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    let privateKey: String = self.enterPrivateKeyTextField.text ?? ""
    self.delegate?.importPrivateKeyViewControllerDidPressNext(
      sender: self,
      privateKey: privateKey,
      name: self.walletNameTextField.text
    )
  }
}

extension KNImportPrivateKeyViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.enterPrivateKeyTextField {
      self.updateNextButton()
    }
    return false
  }
}

extension KNImportPrivateKeyViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.enterPrivateKeyTextField.text = result
      self.updateNextButton()
    }
  }
}
