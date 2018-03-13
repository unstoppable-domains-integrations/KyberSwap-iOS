// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

protocol KNWalletImportingPrivateKeyViewControllerDelegate: class {
  func walletImportingPrivateKeyDidCancel()
  func walletImportingPrivateKeyDidImport(privateKey: String)
}

class KNWalletImportingPrivateKeyViewController: UIViewController {

  fileprivate weak var delegate: KNWalletImportingPrivateKeyViewControllerDelegate?

  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var privateKeyLabel: UILabel!
  @IBOutlet weak var privateKeyTextField: UITextField!
  @IBOutlet weak var importButton: UIButton!

  init(delegate: KNWalletImportingPrivateKeyViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNWalletImportingPrivateKeyViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.privateKeyTextField.text = ""
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NSLog("Did open: \(self.className)")
  }

  fileprivate func setupUI() {
    self.backButton.setTitle("Back".toBeLocalised(), for: .normal)

    self.privateKeyLabel.text = "Private Key".toBeLocalised()
    self.privateKeyTextField.text = ""

    self.importButton.setTitle("Import".uppercased().toBeLocalised(), for: .normal)
    self.importButton.rounded(color: .clear, width: 0, radius: 10.0)
    self.importButton.backgroundColor = UIColor.Kyber.blue
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.walletImportingPrivateKeyDidCancel()
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
    let qrcodeReader = QRCodeReaderViewController()
    qrcodeReader.delegate = self
    self.present(qrcodeReader, animated: true, completion: nil)
  }

  @IBAction func importButtonPressed(_ sender: Any) {
    self.delegate?.walletImportingPrivateKeyDidImport(privateKey: self.privateKeyTextField.text ?? "")
  }
}

extension KNWalletImportingPrivateKeyViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.privateKeyTextField.text = result
    }
  }
}
