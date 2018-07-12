// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

protocol KNImportPrivateKeyViewControllerDelegate: class {
  func importPrivateKeyViewControllerDidPressNext(sender: KNImportPrivateKeyViewController, privateKey: String)
}

class KNImportPrivateKeyViewController: KNBaseViewController {

  weak var delegate: KNImportPrivateKeyViewControllerDelegate?

  private var isSecureText: Bool = true
  @IBOutlet weak var secureTextButton: UIButton!
  @IBOutlet weak var enterPrivateKeyTextLabel: UILabel!
  @IBOutlet weak var enterPrivateKeyTextField: UITextField!
  @IBOutlet weak var privateKeyNoteLabel: UILabel!

  @IBOutlet weak var nextButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.resetUI()
  }

  fileprivate func setupUI() {
    self.enterPrivateKeyTextLabel.text = "1. Enter your Private Key".toBeLocalised()
    self.enterPrivateKeyTextField.rounded(radius: 4.0)
    self.enterPrivateKeyTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.enterPrivateKeyTextField.leftViewMode = .always
    self.enterPrivateKeyTextField.rightViewMode = .always
    self.enterPrivateKeyTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 0))

    self.nextButton.rounded(radius: 4.0)
    self.privateKeyNoteLabel.text = "Private key has to be 64 characaters".toBeLocalised()

    self.resetUI()
  }

  fileprivate func resetUI() {
    self.enterPrivateKeyTextField.text = ""
    self.isSecureText = true
    self.updateSecureTextEntry()
  }

  fileprivate func updateSecureTextEntry() {
    let secureTextImage = UIImage(named: self.isSecureText ? "hide_secure_text" : "show_secure_text")
    self.secureTextButton.setImage(secureTextImage, for: .normal)
    self.enterPrivateKeyTextField.isSecureTextEntry = self.isSecureText
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
    guard privateKey.count == 64 else {
      self.showErrorTopBannerMessage(
        with: "Invalid input".toBeLocalised(),
        message: "Private key should have 64 characters".toBeLocalised()
      )
      return
    }
    self.delegate?.importPrivateKeyViewControllerDidPressNext(
      sender: self,
      privateKey: privateKey
    )
  }
}

extension KNImportPrivateKeyViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.enterPrivateKeyTextField.text = result
    }
  }
}
