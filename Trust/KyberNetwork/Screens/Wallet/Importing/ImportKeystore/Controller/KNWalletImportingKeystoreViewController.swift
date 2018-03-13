// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

protocol KNWalletImportingKeystoreViewControllerDelegate: class {
  func walletImportingKeystoreDidImport(keystore: String, password: String)
  func walletImportingKeystoreDidCancel()
}

class KNWalletImportingKeystoreViewController: UIViewController {

  fileprivate weak var delegate: KNWalletImportingKeystoreViewControllerDelegate?

  @IBOutlet weak var keystoreLabel: UILabel!
  @IBOutlet weak var keystoreJSONTextView: UITextView!

  @IBOutlet weak var passwordLabel: UILabel!
  @IBOutlet weak var passwordTextField: UITextField!

  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var importButton: UIButton!

  init(delegate: KNWalletImportingKeystoreViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNWalletImportingKeystoreViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    //TODO (Mike): Only keep one instance for this view controller
    // Should clear data every time it is opened
//    self.keystoreJSONTextView.text = ""
    self.passwordTextField.text = ""
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NSLog("Did open: \(self.className)")
  }

  fileprivate func setupUI() {
    self.backButton.setTitle("Back".toBeLocalised(), for: .normal)

    self.keystoreLabel.text = "Keystore".toBeLocalised()

    self.keystoreJSONTextView.rounded(color: .clear, width: 0, radius: 5.0)
    //TODO (Mike): Clear keystore text
//    self.keystoreJSONTextView.text = ""

    self.passwordLabel.text = "Password".toBeLocalised()

    self.importButton.rounded(color: .clear, width: 0, radius: 10.0)
    self.importButton.setTitle("Import".uppercased().toBeLocalised(), for: .normal)
    self.importButton.backgroundColor = UIColor.Kyber.blue
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
    let qrcodeVC = QRCodeReaderViewController()
    qrcodeVC.delegate = self
    self.present(qrcodeVC, animated: true, completion: nil)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.walletImportingKeystoreDidCancel()
  }

  @IBAction func importButtonPressed(_ sender: Any) {
    self.delegate?.walletImportingKeystoreDidImport(
      keystore: self.keystoreJSONTextView.text,
      password: self.passwordTextField.text ?? "")
  }
}

extension KNWalletImportingKeystoreViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.keystoreJSONTextView.text = result
    }
  }
}
