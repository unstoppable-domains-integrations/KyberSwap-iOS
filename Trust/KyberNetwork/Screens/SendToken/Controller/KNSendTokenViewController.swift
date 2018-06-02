// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import Result
import QRCodeReaderViewController

protocol KNSendTokenViewControllerDelegate: class {
  func sendTokenViewControllerDidPressToken(sender: KNSendTokenViewController, selectedToken: TokenObject)
  func sendTokenViewControllerDidPressSend(sender: KNSendTokenViewController, transaction: UnconfirmedTransaction)
  func sendTokenViewControllerUpdateEstimatedGasLimit(sender: KNSendTokenViewController, transaction: UnconfirmedTransaction)
  func sendTokenViewControllerDidPressGasPrice(sender: KNSendTokenViewController, gasPrice: BigInt, estGasLimit: BigInt)
  func sendTokenViewControllerDidPressBack(sender: KNSendTokenViewController)
}

class KNSendTokenViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var tokenContainerView: UIView!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var tokenBalanceLabel: UILabel!

  @IBOutlet weak var gasPriceDataDetailsView: KNDataDetailsView!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var sendButton: UIButton!

  @IBOutlet weak var transactionStatusView: KNTransactionStatusView!
  @IBOutlet weak var bottomTransactionStatusViewConstraint: NSLayoutConstraint!

  lazy var toolBar: UIToolbar = {
    let toolBar = UIToolbar()
    toolBar.barStyle = .default
    toolBar.isTranslucent = true
    toolBar.barTintColor = UIColor(hex: "31cb9e")
    toolBar.tintColor = .white
    let exchangeAllBtn = UIBarButtonItem(
      title: "Send All",
      style: .plain,
      target: self,
      action: #selector(self.keyboardSendAllButtonPressed(_:))
    )
    let spaceBtn = UIBarButtonItem(
      barButtonSystemItem: .flexibleSpace,
      target: nil,
      action: nil
    )
    let doneBtn = UIBarButtonItem(
      title: "Done",
      style: .plain,
      target: self,
      action: #selector(self.keyboardDoneButtonPressed(_:))
    )
    toolBar.setItems([exchangeAllBtn, spaceBtn, doneBtn], animated: false)
    toolBar.isUserInteractionEnabled = true
    toolBar.sizeToFit()
    return toolBar
  }()

  weak var delegate: KNSendTokenViewControllerDelegate?
  fileprivate let viewModel: KNSendTokenViewModel
  fileprivate var estGasTimer: Timer?

  init(viewModel: KNSendTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSendTokenViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !self.transactionStatusView.isHidden { self.transactionStatusView.updateViewDidAppear() }
    self.estGasTimer?.invalidate()
    self.estGasTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
      self?.shouldUpdateEstimatedGasLimit(nil)
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.estGasTimer?.invalidate()
    self.view.endEditing(true)
  }

  fileprivate func setupUI() {
    self.setupNavigationView()
    self.setupTokenView()
    self.setupGasPriceView()
    self.setupRecentContact()
    self.setupAddressTextField()
    self.setupSendButton()
  }

  fileprivate func setupNavigationView() {
    self.navTitleLabel.text = self.viewModel.navTitle
  }

  fileprivate func setupTokenView() {
    self.tokenContainerView.rounded(radius: 7.0)
    self.tokenContainerView.addShadow()

    self.amountTextField.text = nil
    self.amountTextField.layer.borderColor = UIColor.lightGray.cgColor
    self.amountTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.amountTextField.leftViewMode = .always
    self.amountTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.amountTextField.rightViewMode = .always
    self.amountTextField.delegate = self
    self.amountTextField.rounded(color: .lightGray, width: 1.0, radius: 4.0)
    self.amountTextField.inputAccessoryView = self.toolBar
    self.amountTextField.becomeFirstResponder()

    self.tokenButton.setImage(UIImage(named: self.viewModel.tokenIconName), for: .normal)
    self.tokenButton.setTitle(self.viewModel.displayToken, for: .normal)

    self.tokenBalanceLabel.text = self.viewModel.displayBalance
  }

  fileprivate func setupGasPriceView() {
    self.gasPriceDataDetailsView.updateView(
      with: "Gas Price",
      subTitle: self.viewModel.displayGasPrice
    )
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.gasPriceDetailsViewPressed(_:)))
    self.gasPriceDataDetailsView.isUserInteractionEnabled = true
    self.gasPriceDataDetailsView.addGestureRecognizer(tapGesture)
  }

  fileprivate func setupRecentContact() {
  }

  fileprivate func setupAddressTextField() {
    self.addressTextField.placeholder = self.viewModel.placeHolderEnterAddress
    self.addressTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.addressTextField.leftViewMode = .always
    self.addressTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 0))
    self.addressTextField.rightViewMode = .always
    self.addressTextField.delegate = self
    self.addressTextField.text = self.viewModel.displayAddress
  }

  fileprivate func setupSendButton() {
    self.sendButton.rounded(radius: 7.0)
    self.transactionStatusView.delegate = self
    self.transactionStatusView.isHidden = true
    self.transactionStatusView.rounded(color: .lightGray, width: 0.2, radius: 7.0)
    self.transactionStatusView.addShadow(color: UIColor.black.withAlphaComponent(0.5))
    self.transactionStatusView.updateView(with: .unknown, txHash: nil)
    self.bottomTransactionStatusViewConstraint.constant = -21 - self.transactionStatusView.frame.height
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.sendTokenViewControllerDidPressBack(sender: self)
  }

  @IBAction func tokenButtonPressed(_ sender: Any) {
    self.delegate?.sendTokenViewControllerDidPressToken(
      sender: self,
      selectedToken: self.viewModel.from
    )
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    guard self.viewModel.isAmountValid else {
      self.showWarningTopBannerMessage(with: "Invalid Amount", message: "Please enter a valid amount to send")
      return
    }
    guard self.viewModel.isAddressValid else {
      self.showWarningTopBannerMessage(with: "Invalid Address", message: "Please enter a valid address to send")
      return
    }
    self.delegate?.sendTokenViewControllerDidPressSend(
      sender: self,
      transaction: self.viewModel.unconfirmTransaction
    )
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
    let qrcodeReaderVC: QRCodeReaderViewController = {
      let controller = QRCodeReaderViewController()
      controller.delegate = self
      return controller
    }()
    self.present(qrcodeReaderVC, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanAction(_ sender: Any) {
    self.delegate?.sendTokenViewControllerDidPressBack(sender: self)
  }

  @objc func gasPriceDetailsViewPressed(_ sender: Any) {
    self.delegate?.sendTokenViewControllerDidPressGasPrice(
      sender: self,
      gasPrice: self.viewModel.gasPrice,
      estGasLimit: self.viewModel.gasLimit
    )
  }

  @objc func keyboardSendAllButtonPressed(_ sender: Any) {
    self.amountTextField.text = self.viewModel.balance?.amountFull ?? ""
    self.amountTextField.resignFirstResponder()
    self.viewModel.updateAmount(self.amountTextField.text ?? "")
    self.shouldUpdateEstimatedGasLimit(nil)
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.amountTextField.resignFirstResponder()
  }

  fileprivate func shouldUpdateEstimatedGasLimit(_ sender: Any?) {
    self.delegate?.sendTokenViewControllerUpdateEstimatedGasLimit(
      sender: self,
      transaction: self.viewModel.unconfirmTransaction
    )
  }
}

// MARK: Update UIs
extension KNSendTokenViewController {
  func updateUIFromTokenDidChange() {
    self.viewModel.updateAmount("")
    self.amountTextField.text = ""
    self.tokenButton.setImage(UIImage(named: self.viewModel.tokenIconName), for: .normal)
    self.tokenButton.setTitle(self.viewModel.displayToken, for: .normal)
    self.updateUIBalanceDidChange()
  }

  func updateUIBalanceDidChange() {
    self.tokenBalanceLabel.text = self.viewModel.displayBalance
    self.view.layoutIfNeeded()
  }

  func updateUIGasPriceDidChange() {
    self.gasPriceDataDetailsView.updateView(
      with: "Gas Price",
      subTitle: self.viewModel.displayGasPrice
    )
    self.view.layoutIfNeeded()
  }

  func updateUIAddressQRCode() {
    self.addressTextField.text = self.viewModel.displayAddress
    self.view.layoutIfNeeded()
  }
}

// MARK: Update from coordinator
extension KNSendTokenViewController {
  func coordinatorDidUpdateSendToken(_ from: TokenObject, balance: Balance?) {
    self.viewModel.updateSendToken(from: from, balance: balance)
    self.updateUIFromTokenDidChange()
  }

  func coordinatorUpdateBalances(_ balances: [String: Balance]) {
    if let balance = balances[self.viewModel.from.contract] {
      self.viewModel.updateBalance(balance)
      self.updateUIBalanceDidChange()
    }
  }

  func coordinatorUpdateGasPrice(_ gasPrice: BigInt) {
    self.viewModel.updateGasPrice(gasPrice)
    self.updateUIGasPriceDidChange()
  }

  /*
   Result from sending exchange token
   */
  func coordinatorSendTokenDidReturn(result: Result<String, AnyError>) {
    if case .failure(let error) = result {
      self.transactionStatusDidPressClose()
      self.displayError(error: error)
    }
  }

  /*
   Show transaction status after user confirmed transaction
   */
  func coordinatorSendTokenUserDidConfirmTransaction() {
    // Reset exchange amount
    self.amountTextField.text = ""
    self.viewModel.updateAmount("")
    self.viewModel.updateAddress("")
    self.updateUIAddressQRCode()
    self.shouldUpdateEstimatedGasLimit(nil)
    self.transactionStatusView.updateView(with: .broadcasting, txHash: nil)
    if !self.transactionStatusView.isHidden { return }
    self.openTransactionStatus()
  }

  /*
    Update transaction status with new status, txHash to avoid updating wrong transation
   - status: either mining or unknown, mining: display for 2 seconds then dismiss; unknown: dismiss
   */
  func coordinatorSendTokenTransactionDidChangeStatus(_ status: KNTransactionStatus, txHash: String? = nil) {
    self.transactionStatusView.updateView(with: status, txHash: txHash)
    if status == .mining {
      Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
        self?.closeTransactionStatus()
      }
    } else {
      self.closeTransactionStatus()
    }
  }

  func coordinatorUpdateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, amount: BigInt) {
    self.viewModel.updateEstimatedGasLimit(gasLimit, from: from, amount: amount)
  }
}

// MARK: UITextFieldDelegate
extension KNSendTokenViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if self.amountTextField == textField {
      self.viewModel.updateAmount("")
    } else {
      self.viewModel.updateAddress("")
    }
    self.shouldUpdateEstimatedGasLimit(nil)
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if self.amountTextField == textField {
      self.viewModel.updateAmount(text)
    } else {
      self.viewModel.updateAddress(text)
    }
    self.shouldUpdateEstimatedGasLimit(nil)
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == self.amountTextField {
      self.amountTextField.layer.borderColor = UIColor(hex: "31cb9e").cgColor
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == self.amountTextField {
      self.amountTextField.layer.borderColor = UIColor.lightGray.cgColor
    }
  }
}

extension KNSendTokenViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.viewModel.updateAddress(result)
      self.updateUIAddressQRCode()
    }
  }
}

// MARK: Transaction Status Delegate
extension KNSendTokenViewController: KNTransactionStatusViewDelegate {
  func transactionStatusDidPressClose() {
    self.closeTransactionStatus()
  }

  fileprivate func openTransactionStatus() {
    if !self.transactionStatusView.isHidden { return }
    UIView.animate(
    withDuration: 0.5) {
      self.transactionStatusView.isHidden = false
      self.bottomTransactionStatusViewConstraint.constant = 21
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func closeTransactionStatus() {
    if self.transactionStatusView.isHidden { return }
    //swiftlint:disable multiple_closures_with_trailing_closure
    //swiftlint:disable opening_brace
    UIView.animate(
      withDuration: 0.5,
      animations: {
        self.bottomTransactionStatusViewConstraint.constant = -21 - self.transactionStatusView.frame.height
        self.view.layoutIfNeeded()
    }){ _ in
      self.transactionStatusView.isHidden = true
    }
  }
}
