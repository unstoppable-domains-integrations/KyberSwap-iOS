// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore
import Result
import QRCodeReaderViewController

enum KSendTokenViewEvent {
  case back
  case searchToken(selectedToken: TokenObject)
  case estimateGas(transaction: UnconfirmedTransaction)
  case setGasPrice(gasPrice: BigInt, gasLimit: BigInt)
  case send(transaction: UnconfirmedTransaction)
  case addContact(address: String)
  case contactSelectMore
}

protocol KSendTokenViewControllerDelegate: class {
  func kSendTokenViewController(_ controller: KSendTokenViewController, run event: KSendTokenViewEvent)
}

class KSendTokenViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var tokenContainerView: UIView!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var balanceTextLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!

  @IBOutlet weak var scrollContainerView: UIScrollView!
  @IBOutlet weak var advancedSettingsView: KAdvancedSettingsView!
  @IBOutlet weak var heightConstraintAdvancedSettingsView: NSLayoutConstraint!

  @IBOutlet weak var moreContactButton: UIButton!
  @IBOutlet weak var recentContactView: UIView!
  @IBOutlet weak var recentContactLabel: UILabel!
  @IBOutlet weak var recentContactTableView: KNContactTableView!
  @IBOutlet weak var recentContactHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var recentContactTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var sendButton: UIButton!

  @IBOutlet weak var newContactButton: UIButton!

  lazy var toolBar: KNCustomToolbar = {
    return KNCustomToolbar(
      leftBtnTitle: "Send All".toBeLocalised(),
      rightBtnTitle: "Done".toBeLocalised(),
      delegate: self
    )
  }()

  lazy var style: KNAppStyleType = {
    return KNAppStyleType.current
  }()

  weak var delegate: KSendTokenViewControllerDelegate?
  fileprivate let viewModel: KNSendTokenViewModel
  fileprivate var estGasTimer: Timer?

  init(viewModel: KNSendTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KSendTokenViewController.className, bundle: nil)
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
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 7),
      opacity: 0.32,
      radius: 32
    )
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUIAddressQRCode()
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
    self.setupAdvancedSettingsView()
    self.setupRecentContact()
    self.setupAddressTextField()
    self.setupSendButton()
  }

  fileprivate func setupNavigationView() {
    self.headerContainerView.backgroundColor = self.style.walletFlowHeaderColor
    self.navTitleLabel.text = self.viewModel.navTitle
  }

  fileprivate func setupTokenView() {
    self.tokenContainerView.rounded(radius: 4.0)
    self.tokenButton.titleLabel?.numberOfLines = 2
    self.tokenButton.titleLabel?.lineBreakMode = .byWordWrapping

    self.amountTextField.text = nil
    self.amountTextField.adjustsFontSizeToFitWidth = true
    self.amountTextField.delegate = self
    self.amountTextField.inputAccessoryView = self.toolBar

    self.tokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.tokenButton.setAttributedTitle(self.viewModel.tokenButtonAttributedText, for: .normal)

    self.balanceTextLabel.text = self.viewModel.balanceText
    self.tokenBalanceLabel.text = self.viewModel.displayBalance
  }

  fileprivate func setupRecentContact() {
    self.recentContactView.isHidden = true
    self.recentContactTableView.delegate = self
    self.recentContactTableView.updateScrolling(isEnabled: false)
    self.recentContactTableView.shouldUpdateContacts(nil)
    self.moreContactButton.setTitleColor(
      self.style.walletFlowHeaderColor,
      for: .normal
    )
    self.moreContactButton.setTitle(
      self.style.buttonTitle(with: "More"),
      for: .normal
    )
  }

  fileprivate func setupAdvancedSettingsView() {
    let viewModel = KAdvancedSettingsViewModel(
      hasMinRate: false,
      brandColor: KNAppStyleType.current.walletFlowHeaderColor
    )
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas
    )
    viewModel.updateGasLimit(self.viewModel.gasLimit)
    viewModel.updateViewHidden(isHidden: true)
    self.advancedSettingsView.updateViewModel(viewModel)
    self.heightConstraintAdvancedSettingsView.constant = self.advancedSettingsView.height
    self.advancedSettingsView.delegate = self
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraints()
  }

  fileprivate func setupAddressTextField() {
    self.addressTextField.placeholder = self.viewModel.placeHolderEnterAddress
    self.addressTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.addressTextField.leftViewMode = .always
    self.addressTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 0))
    self.addressTextField.rightViewMode = .always
    self.addressTextField.delegate = self
    self.addressTextField.text = self.viewModel.displayAddress
    self.newContactButton.setTitle(
      self.style.buttonTitle(with: "Add Contact".toBeLocalised()),
      for: .normal
    )
    self.newContactButton.setTitleColor(
      self.style.walletFlowHeaderColor,
      for: .normal
    )
  }

  fileprivate func setupSendButton() {
    self.sendButton.rounded(radius: self.style.buttonRadius(for: self.sendButton.frame.height))
    self.sendButton.backgroundColor = self.style.walletFlowHeaderColor
    self.sendButton.setTitle(
      self.style.buttonTitle(with: "Send".toBeLocalised()),
      for: .normal
    )
  }

  fileprivate func updateAdvancedSettingsView() {
    self.advancedSettingsView.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      gasLimit: self.viewModel.gasLimit
    )
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kSendTokenViewController(self, run: .back)
  }

  @IBAction func tokenButtonPressed(_ sender: Any) {
    self.amountTextField.resignFirstResponder()
    self.delegate?.kSendTokenViewController(self, run: .searchToken(selectedToken: self.viewModel.from))
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    guard !self.viewModel.isAmountTooSmall else {
      self.showWarningTopBannerMessage(
        with: "Invalid Amount".toBeLocalised(),
        message: "Amount too small to perform send".toBeLocalised()
      )
      return
    }
    guard !self.viewModel.isAmountTooBig else {
      self.showWarningTopBannerMessage(
        with: "Invalid Amount".toBeLocalised(),
        message: "Amount too big to perform send".toBeLocalised()
      )
      return
    }
    guard self.viewModel.isAddressValid else {
      self.showWarningTopBannerMessage(
        with: "Invalid Address".toBeLocalised(),
        message: "Please enter a valid address to send".toBeLocalised()
      )
      return
    }
    self.delegate?.kSendTokenViewController(self, run: .send(transaction: self.viewModel.unconfirmTransaction))
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
      self.delegate?.kSendTokenViewController(self, run: .back)
    }
  }

  @IBAction func recentContactMoreButtonPressed(_ sender: Any) {
    self.delegate?.kSendTokenViewController(self, run: .contactSelectMore)
  }

  @IBAction func newContactButtonPressed(_ sender: Any) {
    self.delegate?.kSendTokenViewController(self, run: .addContact(address: self.viewModel.addressString))
  }

  @objc func keyboardSendAllButtonPressed(_ sender: Any) {
    self.amountTextField.text = self.viewModel.allTokenBalanceString
    self.viewModel.updateAmount(self.amountTextField.text ?? "")
    self.amountTextField.resignFirstResponder()
    self.shouldUpdateEstimatedGasLimit(nil)
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.amountTextField.resignFirstResponder()
  }

  fileprivate func shouldUpdateEstimatedGasLimit(_ sender: Any?) {
    let event = KSendTokenViewEvent.estimateGas(transaction: self.viewModel.unconfirmTransaction)
    self.delegate?.kSendTokenViewController(self, run: event)
  }
}

// MARK: Update UIs
extension KSendTokenViewController {
  func updateUIFromTokenDidChange() {
    self.viewModel.updateAmount("")
    self.amountTextField.text = ""
    self.tokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.tokenButton.setAttributedTitle(self.viewModel.tokenButtonAttributedText, for: .normal)
    self.updateUIBalanceDidChange()
  }

  func updateUIBalanceDidChange() {
    self.tokenBalanceLabel.text = self.viewModel.displayBalance
    self.balanceTextLabel.text = self.viewModel.balanceText
    if !self.amountTextField.isEditing {
      self.amountTextField.textColor = self.viewModel.amountTextColor
    }
    self.view.layoutIfNeeded()
  }

  func updateUIAddressQRCode() {
    self.addressTextField.text = self.viewModel.displayAddress
    self.newContactButton.setTitle(self.viewModel.newContactTitle, for: .normal)
    self.view.layoutIfNeeded()
  }
}

// MARK: Update from coordinator
extension KSendTokenViewController {
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
    self.shouldUpdateEstimatedGasLimit(nil)
  }

  func coordinatorUpdateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, amount: BigInt) {
    self.viewModel.updateEstimatedGasLimit(gasLimit, from: from, amount: amount)
    self.updateAdvancedSettingsView()
  }

  func coordinatorUpdateGasPriceCached() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
    self.updateAdvancedSettingsView()
  }

  func coordinatorDidSelectContact(_ contact: KNContact) {
    self.viewModel.updateAddress(contact.address)
    self.updateUIAddressQRCode()
  }

  func coordinatorSend(to address: String) {
    self.viewModel.updateAddress(address)
    self.updateUIAddressQRCode()
  }
}

// MARK: UITextFieldDelegate
extension KSendTokenViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if self.amountTextField == textField {
      self.viewModel.updateAmount("")
    } else {
      self.viewModel.updateAddress("")
      self.updateUIAddressQRCode()
    }
    self.shouldUpdateEstimatedGasLimit(nil)
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()
    if textField == self.amountTextField, text.fullBigInt(decimals: self.viewModel.from.decimals) == nil { return false }
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
    self.amountTextField.textColor = UIColor.Kyber.lightSeaGreen
    if textField == self.addressTextField {
      self.addressTextField.text = self.viewModel.addressString
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.amountTextField.textColor = self.viewModel.amountTextColor
    if textField == self.addressTextField {
      self.updateUIAddressQRCode()
    }
  }
}

extension KSendTokenViewController: QRCodeReaderDelegate {
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

extension KSendTokenViewController: KNContactTableViewDelegate {
  func contactTableView(_ tableView: UITableView, run event: KNContactTableViewEvent) {
    switch event {
    case .update(let height):
      self.updateContactTableView(height: height)
    case .select(let contact):
      self.contactTableView(select: contact)
    case .edit(let contact):
      self.delegate?.kSendTokenViewController(self, run: .addContact(address: contact.address))
    case .delete(let contact):
      self.contactTableView(delete: contact)
    case .send(let address):
      if let contact = KNContactStorage.shared.get(forPrimaryKey: address) {
        self.contactTableView(select: contact)
      } else {
        self.viewModel.updateAddress(address)
        self.updateUIAddressQRCode()
      }
    }
  }

  fileprivate func updateContactTableView(height: CGFloat) {
    UIView.animate(
    withDuration: 0.25) {
      self.recentContactView.isHidden = (height == 0)
      self.recentContactHeightConstraint.constant = height == 0 ? 0 : height + 34.0
      self.recentContactTableViewHeightConstraint.constant = height
      self.updateUIAddressQRCode()
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func contactTableView(select contact: KNContact) {
    self.viewModel.updateAddress(contact.address)
    self.updateUIAddressQRCode()
    KNContactStorage.shared.updateLastUsed(contact: contact)
  }

  fileprivate func contactTableView(delete contact: KNContact) {
    let alertController = UIAlertController(
      title: "Do you want to delete this contact?".toBeLocalised(),
      message: "",
      preferredStyle: .actionSheet
    )
    alertController.addAction(UIAlertAction(title: "Delete".toBeLocalised(), style: .destructive, handler: { _ in
      KNContactStorage.shared.delete(contacts: [contact])
    }))
    alertController.addAction(UIAlertAction(title: "Cancel".toBeLocalised(), style: .cancel, handler: nil))
    self.present(alertController, animated: true, completion: nil)
  }
}

extension KSendTokenViewController: KNCustomToolbarDelegate {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardSendAllButtonPressed(toolbar)
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}

// MARK: Advanced Settings View
extension KSendTokenViewController: KAdvancedSettingsViewDelegate {
  func kAdvancedSettingsView(_ view: KAdvancedSettingsView, run event: KAdvancedSettingsViewEvent) {
    switch event {
    case .displayButtonPressed:
      UIView.animate(
        withDuration: 0.32,
        animations: {
          self.heightConstraintAdvancedSettingsView.constant = self.advancedSettingsView.height
          self.updateAdvancedSettingsView()
          self.view.layoutIfNeeded()
      }, completion: { _ in
        if self.advancedSettingsView.isExpanded {
          let bottomOffset = CGPoint(
            x: 0,
            y: self.scrollContainerView.contentSize.height - self.scrollContainerView.bounds.size.height
          )
          self.scrollContainerView.setContentOffset(bottomOffset, animated: true)
        }
      })
    case .gasPriceChanged(let type):
      self.viewModel.updateSelectedGasPriceType(type)
      self.updateAdvancedSettingsView()
    default: break
    }
  }
}
