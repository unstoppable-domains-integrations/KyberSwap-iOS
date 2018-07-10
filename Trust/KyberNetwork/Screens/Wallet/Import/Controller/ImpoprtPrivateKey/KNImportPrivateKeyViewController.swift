// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

protocol KNImportPrivateKeyViewControllerDelegate: class {
  func importPrivateKeyViewControllerDidPressNext(sender: KNImportPrivateKeyViewController, privateKey: String)
}

class KNImportPrivateKeyViewController: KNBaseViewController {

  weak var delegate: KNImportPrivateKeyViewControllerDelegate?

  @IBOutlet weak var enterPrivateKeyTextLabel: UILabel!
  @IBOutlet weak var enterPrivateKeyTextField: UITextField!

  @IBOutlet weak var nextButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.enterPrivateKeyTextField.text = ""
  }

  fileprivate func setupUI() {
    self.enterPrivateKeyTextLabel.text = "1. Enter your Private Key".toBeLocalised()
    self.enterPrivateKeyTextField.rounded(radius: 4.0)
    self.enterPrivateKeyTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.enterPrivateKeyTextField.leftViewMode = .always
    self.enterPrivateKeyTextField.rightViewMode = .always
    self.enterPrivateKeyTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 0))

    self.nextButton.rounded(radius: 4.0)
  }

  @IBAction func qrCodeButtonPressed(_ sender: Any) {
    let qrcodeReader = QRCodeReaderViewController()
    qrcodeReader.delegate = self
    self.parent?.present(qrcodeReader, animated: true, completion: nil)
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    let privateKey: String = self.enterPrivateKeyTextField.text ?? ""
    if privateKey.isEmpty {
      self.showWarningTopBannerMessage(
        with: "Field Required".toBeLocalised(),
        message: "Please check your input data again.".toBeLocalised()
      )
    } else {
      self.delegate?.importPrivateKeyViewControllerDidPressNext(
        sender: self,
        privateKey: privateKey
      )
    }
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
