// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import Result
import QRCodeReaderViewController

enum KNSendTokenViewEvent {
  case back
  case searchToken(selectedToken: TokenObject)
  case estimateGas(transaction: UnconfirmedTransaction)
  case setGasPrice(gasPrice: BigInt, gasLimit: BigInt)
  case send(transaction: UnconfirmedTransaction)
}

protocol KNSendTokenViewControllerDelegate: class {
  func sendTokenViewController(_ controller: KNSendTokenViewController, run event: KNSendTokenViewEvent)
}

class KNSendTokenViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var tokenContainerView: UIView!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var balanceTextLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!

  @IBOutlet weak var recentContactView: UIView!
  @IBOutlet weak var recentContactLabel: UILabel!
  @IBOutlet weak var recentContactTableView: KNContactTableView!
  @IBOutlet weak var recentContactHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var gasPriceOptionButton: UIButton!
  @IBOutlet weak var gasPriceSegmentedControl: UISegmentedControl!
  @IBOutlet weak var gasPriceTextLabel: UILabel!

  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var sendButton: UIButton!

  lazy var toolBar: KNCustomToolbar = {
    return KNCustomToolbar(
      leftBtnTitle: "Send All",
      rightBtnTitle: "Done",
      delegate: self
    )
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

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.tokenContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.5),
      offset: CGSize(width: 0, height: 7),
      opacity: 0.32,
      radius: 32
    )
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
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
    self.amountTextField.resignFirstResponder()
  }

  fileprivate func setupUI() {
    self.setupNavigationView()
    self.setupTokenView()
    self.setupGasPriceView()
    self.setupRecentContact()
    self.setupAddressTextField()
  }

  fileprivate func setupNavigationView() {
    self.navTitleLabel.text = self.viewModel.navTitle
  }

  fileprivate func setupTokenView() {
    self.tokenContainerView.rounded(radius: 7.0)
    self.tokenContainerView.addShadow()
    self.tokenButton.titleLabel?.numberOfLines = 2
    self.tokenButton.titleLabel?.lineBreakMode = .byWordWrapping

    self.amountTextField.text = nil
    self.amountTextField.adjustsFontSizeToFitWidth = true
    self.amountTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.amountTextField.leftViewMode = .always
    self.amountTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
    self.amountTextField.rightViewMode = .always
    self.amountTextField.delegate = self
    self.amountTextField.inputAccessoryView = self.toolBar

    self.tokenButton.setImage(UIImage(named: self.viewModel.tokenIconName) ?? UIImage(named: "accounts_active"), for: .normal)
    self.tokenButton.setAttributedTitle(self.viewModel.tokenButtonAttributedText, for: .normal)

    self.balanceTextLabel.text = self.viewModel.balanceText
    self.tokenBalanceLabel.text = self.viewModel.displayBalance
  }

  fileprivate func setupGasPriceView() {
    self.gasPriceOptionButton.setImage(UIImage(named: "expand_icon"), for: .normal)
    self.gasPriceSegmentedControl.selectedSegmentIndex = 0 // select fast option
    self.gasPriceSegmentedControl.addTarget(self, action: #selector(self.gasPriceSegmentedControlDidTouch(_:)), for: .touchDown)
    self.gasPriceSegmentedControl.isHidden = true
    self.gasPriceTextLabel.isHidden = true
  }

  fileprivate func setupRecentContact() {
    self.recentContactView.isHidden = true
    self.recentContactTableView.delegate = self
    self.recentContactTableView.updateScrolling(isEnabled: false)
    self.recentContactTableView.shouldUpdateContacts(nil)
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

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.sendTokenViewController(self, run: .back)
  }

  @IBAction func tokenButtonPressed(_ sender: Any) {
    self.amountTextField.resignFirstResponder()
    self.delegate?.sendTokenViewController(self, run: .searchToken(selectedToken: self.viewModel.from))
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
    self.delegate?.sendTokenViewController(self, run: .send(transaction: self.viewModel.unconfirmTransaction))
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
    let qrcodeReaderVC: QRCodeReaderViewController = {
      let controller = QRCodeReaderViewController()
      controller.delegate = self
      return controller
    }()
    self.present(qrcodeReaderVC, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.sendTokenViewController(self, run: .back)
    }
  }

  @IBAction func gasPriceButtonPressed(_ sender: Any) {
    UIView.animate(withDuration: 0.3) {
      self.gasPriceSegmentedControl.isHidden = !self.gasPriceSegmentedControl.isHidden
      self.gasPriceTextLabel.isHidden = !self.gasPriceTextLabel.isHidden
      self.gasPriceOptionButton.setImage(
        UIImage(named: self.gasPriceTextLabel.isHidden ? "expand_icon" : "collapse_icon"), for: .normal)
    }
  }

  @objc func gasPriceSegmentedControlDidTouch(_ sender: Any) {
    let selectedId = self.gasPriceSegmentedControl.selectedSegmentIndex
    if selectedId == 3 {
      self.amountTextField.resignFirstResponder()
      // custom gas price
      let event = KNSendTokenViewEvent.setGasPrice(
        gasPrice: self.viewModel.gasPrice,
        gasLimit: self.viewModel.gasLimit
      )
      self.delegate?.sendTokenViewController(self, run: event)
    } else {
      self.viewModel.updateSelectedGasPriceType(KNSelectedGasPriceType(rawValue: selectedId) ?? .fast)
    }
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
    let event = KNSendTokenViewEvent.estimateGas(transaction: self.viewModel.unconfirmTransaction)
    self.delegate?.sendTokenViewController(self, run: event)
  }

  func coordinatorUpdateGasPriceCached() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
  }
}

// MARK: Update UIs
extension KNSendTokenViewController {
  func updateUIFromTokenDidChange() {
    self.viewModel.updateAmount("")
    self.amountTextField.text = ""
    self.tokenButton.setImage(UIImage(named: self.viewModel.tokenIconName) ?? UIImage(named: "accounts_active"), for: .normal)
    self.tokenButton.setAttributedTitle(self.viewModel.tokenButtonAttributedText, for: .normal)
    self.updateUIBalanceDidChange()
  }

  func updateUIBalanceDidChange() {
    self.tokenBalanceLabel.text = self.viewModel.displayBalance
    self.balanceTextLabel.text = self.viewModel.balanceText
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

  func coordinatorUpdateGasPrice(_ gasPrice: BigInt?) {
    if let gasPrice = gasPrice {
      self.viewModel.updateGasPrice(gasPrice)
    }
    self.gasPriceSegmentedControl.selectedSegmentIndex = self.viewModel.selectedGasPriceType.rawValue
  }

  /*
   Result from sending exchange token
   */
  func coordinatorSendTokenDidReturn(result: Result<String, AnyError>) {
    if case .failure(let error) = result {
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
  }

  func coordinatorUpdateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, amount: BigInt) {
    self.viewModel.updateEstimatedGasLimit(gasLimit, from: from, amount: amount)
  }

  func coordinatorGasPriceCachedDidUpdate() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
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
    self.amountTextField.textColor = UIColor(hex: "31cb9e")
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.amountTextField.textColor = self.viewModel.amountTextColor
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

extension KNSendTokenViewController: KNContactTableViewDelegate {
  func contactTableView(_ sender: KNContactTableView, didUpdate height: CGFloat) {
    self.recentContactView.isHidden = (height == 0)
    self.recentContactHeightConstraint.constant = height + 34.0
    self.view.layoutIfNeeded()
  }

  func contactTableView(_ sender: KNContactTableView, didSelect contact: KNContact) {
    self.addressTextField.text = contact.address
    KNContactStorage.shared.updateLastUsed(contact: contact)
  }
}

extension KNSendTokenViewController: KNCustomToolbarDelegate {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardSendAllButtonPressed(toolbar)
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}
