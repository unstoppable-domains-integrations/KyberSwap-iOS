// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

protocol KNWalletImportingPrivateKeyViewControllerDelegate: class {
  func walletImportingPrivateKeyDidCancel()
  func walletImportingPrivateKeyDidImport(privateKey: String)
}

class KNWalletImportingPrivateKeyViewController: KNBaseViewController {

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
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.privateKeyTextField.text = ""
  }

  fileprivate func setupUI() {
    self.backButton.setTitle("Back".toBeLocalised(), for: .normal)

    self.privateKeyLabel.text = "Private Key".toBeLocalised()
    self.privateKeyTextField.text = ""

    self.importButton.setTitle("Import".uppercased().toBeLocalised(), for: .normal)
    self.importButton.rounded(color: .clear, width: 0, radius: 5.0)
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

  @IBAction func importFilebuttonPressed(_ sender: Any) {
    let types = ["public.text", "public.content", "public.item", "public.data"]
    let controller = TrustDocumentPickerViewController(documentTypes: types, in: .import)
    controller.delegate = self
    controller.modalPresentationStyle = .formSheet
    present(controller, animated: true, completion: nil)
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

extension KNWalletImportingPrivateKeyViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    if controller.documentPickerMode == UIDocumentPickerMode.import {
      if let text = try? String(contentsOfFile: url.path) {
        self.privateKeyTextField.text = text
      }
    }
  }
}
