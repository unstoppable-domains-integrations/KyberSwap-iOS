// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Eureka
import TrustKeystore
import QRCodeReaderViewController

struct KNNewCustomTokenViewModel {

  fileprivate let token: ERC20Token?

  init(token: ERC20Token?) {
    self.token = token
  }

  var title: String {
    return self.token == nil ? "Add Custom Token".toBeLocalised() : "Edit Custom Token".toBeLocalised()
  }
  var contract: String? {
    return self.token?.contract.description
  }

  var name: String? {
    return self.token?.name
  }

  var symbol: String? {
    return self.token?.symbol
  }

  var decimals: String? {
    if let decimals = self.token?.decimals {
      return "\(decimals)"
    }
    return nil
  }
}

protocol KNNewCustomTokenViewControllerDelegate: class {
  func didAddToken(_ token: ERC20Token, in viewController: KNNewCustomTokenViewController)
  func didCancel(in viewController: KNNewCustomTokenViewController)
}

class KNNewCustomTokenViewController: KNBaseViewController {
  fileprivate let viewModel: KNNewCustomTokenViewModel
  fileprivate weak var delegate: KNNewCustomTokenViewControllerDelegate?

  init(viewModel: KNNewCustomTokenViewModel, delegate: KNNewCustomTokenViewControllerDelegate?) {
    self.viewModel = viewModel
    self.delegate = delegate
    super.init(nibName: KNNewCustomTokenViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupNavigationBar()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = self.viewModel.title
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(self.addButtonPressed(_:)))
    self.navigationItem.rightBarButtonItem?.tintColor = .white
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = .white
  }

  @objc func cancelButtonPressed(_ sender: Any) {
    self.delegate?.didCancel(in: self)
  }

  @objc func addButtonPressed(_ sender: Any) {
    //    self.delegate?.didAddToken(token, in: self)
  }

  @objc func openQRCodeReader() {
    let controller = QRCodeReaderViewController()
    controller.delegate = self
    self.present(controller, animated: true, completion: nil)
  }

  @objc func pasteAction() {
    guard let value = UIPasteboard.general.string?.trimmed else {
      return self.displayError(error: SendInputErrors.emptyClipBoard)
    }

    guard CryptoAddressValidator.isValidAddress(value) else {
      return self.displayError(error: Errors.invalidAddress)
    }

    self.updateContractValue(value: value)
  }

  private func updateContractValue(value: String) {
  }
}

extension KNNewCustomTokenViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.stopScanning()
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.stopScanning()
    reader.dismiss(animated: true, completion: nil)
    guard let result = QRURLParser.from(string: result) else { return }
    self.updateContractValue(value: result.address)
  }
}
