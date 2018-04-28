// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Eureka
import TrustKeystore
import QRCodeReaderViewController

protocol KNNewCustomTokenViewControllerDelegate: class {
  func didAddToken(_ token: ERC20Token, in viewController: KNNewCustomTokenViewController)
  func didCancel(in viewController: KNNewCustomTokenViewController)
}

struct KNNewCustomTokenViewModel {

  fileprivate var token: ERC20Token?

  init(token: ERC20Token?) {
    self.token = token
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

class KNNewCustomTokenViewController: FormViewController {

  fileprivate let viewModel: KNNewCustomTokenViewModel

  private struct Values {
    static let contract = "contract"
    static let name = "name"
    static let symbol = "symbol"
    static let decimals = "decimals"
  }

  fileprivate weak var delegate: KNNewCustomTokenViewControllerDelegate?
  fileprivate var token: ERC20Token?

  private var contractRow: TextFloatLabelRow? {
    return form.rowBy(tag: Values.contract) as? TextFloatLabelRow
  }

  private var nameRow: TextFloatLabelRow? {
    return form.rowBy(tag: Values.name) as? TextFloatLabelRow
  }

  private var symbolRow: TextFloatLabelRow? {
    return form.rowBy(tag: Values.symbol) as? TextFloatLabelRow
  }

  private var decimalsRow: TextFloatLabelRow? {
    return form.rowBy(tag: Values.decimals) as? TextFloatLabelRow
  }

  init(viewModel: KNNewCustomTokenViewModel, delegate: KNNewCustomTokenViewControllerDelegate?) {
    self.viewModel = viewModel
    self.delegate = delegate
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupNavigationBar()

    let recipientRightView = FieldAppereance.addressFieldRightView(
      pasteAction: { [unowned self] in self.pasteAction() },
      qrAction: { [unowned self] in self.openQRCodeReader() }
    )

    self.form = Section()

    +++ Section()

    <<< AppFormAppearance.textFieldFloat(tag: Values.contract) { [unowned self] in
      $0.add(rule: EthereumAddressRule())
      $0.validationOptions = .validatesOnDemand
      $0.title = NSLocalizedString("Contract Address", value: "Contract Address", comment: "")
      $0.value = self.viewModel.contract
    }.cellUpdate { cell, _ in
      cell.textField.textAlignment = .left
      cell.textField.rightView = recipientRightView
      cell.textField.rightViewMode = .always
    }

    <<< AppFormAppearance.textFieldFloat(tag: Values.name) { [unowned self] in
      $0.add(rule: RuleRequired())
      $0.validationOptions = .validatesOnDemand
      $0.title = NSLocalizedString("Name", value: "Name", comment: "")
      $0.value = self.viewModel.name
    }

    <<< AppFormAppearance.textFieldFloat(tag: Values.symbol) { [unowned self] in
      $0.add(rule: RuleRequired())
      $0.validationOptions = .validatesOnDemand
      $0.title = NSLocalizedString("Symbol", value: "Symbol", comment: "")
      $0.value = self.viewModel.symbol
    }

    <<< AppFormAppearance.textFieldFloat(tag: Values.decimals) { [unowned self] in
      $0.add(rule: RuleRequired())
      $0.add(rule: RuleMaxLength(maxLength: 32))
      $0.validationOptions = .validatesOnDemand
      $0.title = NSLocalizedString("Decimals", value: "Decimals", comment: "")
      $0.cell.textField.keyboardType = .decimalPad
      $0.value = self.viewModel.decimals
    }
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = self.token == nil ? "Add Custom Token".toBeLocalised() : "Edit Custom Token".toBeLocalised()
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(self.addButtonPressed(_:)))
    self.navigationItem.rightBarButtonItem?.tintColor = .white
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = .white
  }

  @objc func cancelButtonPressed(_ sender: Any) {
    self.delegate?.didCancel(in: self)
  }

  @objc func addButtonPressed(_ sender: Any) {
    guard self.form.validate().isEmpty else { return }

    let contract = contractRow?.value ?? ""
    let name = nameRow?.value ?? ""
    let symbol = symbolRow?.value ?? ""
    let decimals = Int(decimalsRow?.value ?? "") ?? 0

    guard let address = Address(string: contract) else {
      return self.displayError(error: Errors.invalidAddress)
    }

    let token = ERC20Token(
      contract: address,
      name: name,
      symbol: symbol,
      decimals: decimals
    )
    self.delegate?.didAddToken(token, in: self)
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
    self.contractRow?.value = value
    self.contractRow?.reload()
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
