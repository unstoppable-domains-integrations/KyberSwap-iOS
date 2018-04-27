// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import BigInt
import TrustKeystore
import QRCodeReaderViewController

protocol KNTransferTokenViewControllerDelegate: class {
  func transferTokenViewControllerDidClickTokenButton(_ selectedToken: KNToken)
  func transferTokenViewControllerShouldUpdateEstimatedGas(from token: KNToken, to address: String?, amount: BigInt)
  func transferTokenViewControllerDidClickTransfer(transaction: UnconfirmedTransaction)
  func transferTokenViewControllerDidClickPendingTransaction()
  func transferTokenViewControllerDidExit()
}

class KNTransferTokenViewController: KNBaseViewController {

  fileprivate let kAdvancedSettingsHeight: CGFloat = 120
  fileprivate let kTransferButtonTopPaddingiPhone5: CGFloat = 60
  fileprivate let kTransferButtonTopPaddingAdvancedSettingsOpen: CGFloat = 160
  fileprivate let kTransferButtonTopPaddingiPhone6: CGFloat = 160
  fileprivate let kTransferButtonTopPaddingiPhone6Plus: CGFloat = 200

  fileprivate weak var delegate: KNTransferTokenViewControllerDelegate?

  fileprivate var ethToken: KNToken!
  fileprivate var selectedToken: KNToken!

  fileprivate var otherTokenBalances: [String: Balance] = [:]
  fileprivate var lastEstimateGasUsed: BigInt = KNGasConfiguration.transferETHGasLimitDefault
  fileprivate var estimateGasUsedTimer: Timer?

  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var amountTextLabel: UILabel!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet var percentageButtons: [UIButton]!

  @IBOutlet weak var toAddressTextLabel: UILabel!
  @IBOutlet weak var addressTextField: UITextField!

  @IBOutlet weak var advancedSwitch: UISwitch!
  @IBOutlet weak var advancedTextLabel: UILabel!
  @IBOutlet weak var advancedSettingsView: UIView!

  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var gasPriceTextField: UITextField!
  @IBOutlet weak var lowGasPriceButton: UIButton!
  @IBOutlet weak var standardGasPriceButton: UIButton!
  @IBOutlet weak var fastGasPriceButton: UIButton!
  @IBOutlet weak var transactionFeeLabel: UILabel!
  @IBOutlet weak var transferButton: UIButton!

  @IBOutlet weak var heightConstraintForAdvancedSettingsView: NSLayoutConstraint!
  @IBOutlet weak var topPaddingConstraintForTransferButton: NSLayoutConstraint!

  init(delegate: KNTransferTokenViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNTransferTokenViewController.className, bundle: nil)
    self.loadViewIfNeeded()
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
    self.estimateGasUsedTimer?.invalidate()
    self.shouldUpdateEstimateGasUsed(nil)
    self.estimateGasUsedTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
      self?.shouldUpdateEstimateGasUsed(timer)
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.estimateGasUsedTimer?.invalidate()
    self.estimateGasUsedTimer = nil
  }
}

// MARK: Set up UI
extension KNTransferTokenViewController {
  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupFromToken()
    self.setupAddress()
    self.setupAdvancedSettingsView()
    self.setupTransferButton()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .plain, target: self, action: #selector(self.exitButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "pending_white_icon"), style: .plain, target: self, action: #selector(self.pendingTransactionsPressed(_:)))
    self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
  }

  fileprivate func setupFromToken() {
    self.ethToken = KNJSONLoaderUtil.shared.tokens.first(where: { $0.isETH })!
    self.selectedToken = self.ethToken

    self.fromTextLabel.text = "From".toBeLocalised()
    self.tokenButton.rounded(color: .white, width: 1.0, radius: 5.0)

    self.amountTextLabel.text = "Amount".toBeLocalised()
    self.amountTextField.delegate = self

    for button in self.percentageButtons { button.rounded(color: .clear, width: 0, radius: 4.0) }
    self.updateTokenViewSelectedTokenDidChange()
  }

  fileprivate func setupAddress() {
    self.toAddressTextLabel.text = "To Address".toBeLocalised()
    //TODO (Mike): Remove default value
    self.addressTextField.text = ""
    self.addressTextField.delegate = self
  }

  fileprivate func setupAdvancedSettingsView() {
    self.gasPriceTextField.text = KNGasConfiguration.gasPriceDefault.fullString(units: UnitConfiguration.gasPriceUnit)
    self.gasPriceTextField.delegate = self

    self.lowGasPriceButton.setTitle("Low".toBeLocalised(), for: .normal)
    self.lowGasPriceButton.rounded(color: .clear, width: 0, radius: 4.0)

    self.standardGasPriceButton.setTitle("Standard".toBeLocalised(), for: .normal)
    self.standardGasPriceButton.rounded(color: .clear, width: 0, radius: 4.0)

    self.fastGasPriceButton.setTitle("Fast".toBeLocalised(), for: .normal)
    self.fastGasPriceButton.rounded(color: .clear, width: 0, radius: 4.0)

    let feeString: String = {
      let fee = KNGasConfiguration.gasPriceDefault * self.lastEstimateGasUsed
      return fee.shortString(units: UnitConfiguration.gasFeeUnit)
    }()

    self.transactionFeeLabel.text = "Transaction Fee: \(feeString) ETH".toBeLocalised()
    self.advancedTextLabel.text = "Advanced".toBeLocalised()

    self.topPaddingConstraintForTransferButton.constant = UIDevice.isIphone5 ? kTransferButtonTopPaddingiPhone5 : kTransferButtonTopPaddingiPhone6
    self.advancedSettingsView.isHidden = true
  }

  fileprivate func setupTransferButton() {
    self.transferButton.setTitle("Transfer".uppercased().toBeLocalised(), for: .normal)
    self.transferButton.rounded(color: .clear, width: 0, radius: 5.0)
  }
}

// MARK: Internal update UI and data
extension KNTransferTokenViewController {
  fileprivate func updateTokenViewSelectedTokenDidChange() {
    self.tokenButton.setImage(UIImage(named: self.selectedToken.icon), for: .normal)
    self.tokenButton.setTitle("\(self.selectedToken.display)", for: .normal)
    self.updateViewWhenBalancesDidChange()
    self.amountTextField.text = "0"
  }

  fileprivate func updateSelectedToken(_ token: KNToken) {
    self.selectedToken = token
    let estGasUsed: BigInt = token.isETH ? KNGasConfiguration.transferETHGasLimitDefault : KNGasConfiguration.transferTokenGasLimitDefault
    self.updateTokenViewSelectedTokenDidChange()
    self.updateEstimateGasUsed(estGasUsed)
  }

  fileprivate func updateEstimateGasUsed(_ estimateGas: BigInt) {
    self.lastEstimateGasUsed = estimateGas
    self.updateTransactionFee()
  }

  fileprivate func updateTransactionFee() {
    let fee: BigInt = {
      let gasPrice: BigInt = {
        if let gasPriceBigInt = self.gasPriceTextField.text?.fullBigInt(units: UnitConfiguration.gasPriceUnit) {
          return gasPriceBigInt
        }
        return KNGasConfiguration.gasPriceDefault
      }()
      return gasPrice * self.lastEstimateGasUsed
    }()
    self.transactionFeeLabel.text = "Transaction Fee: \(fee.shortString(units: EthereumUnit.ether)) ETH"
  }

  fileprivate func updateViewWhenBalancesDidChange() {
    let sourceBalance = self.otherTokenBalances[self.selectedToken.address]?.amountShort ?? "0.0000"
    self.tokenBalanceLabel.text = "Balance: \(sourceBalance) \(self.selectedToken.symbol)".toBeLocalised()
  }

  @objc func shouldUpdateEstimateGasUsed(_ sender: Any?) {
    guard let amount = self.amountTextField.text?.fullBigInt(decimals: self.selectedToken.decimal) else { return }
    self.delegate?.transferTokenViewControllerShouldUpdateEstimatedGas(
      from: self.selectedToken,
      to: self.addressTextField.text,
      amount: amount
    )
  }
}

// MARK: Action handlers
extension KNTransferTokenViewController {
  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.transferTokenViewControllerDidExit()
  }

  @objc func pendingTransactionsPressed(_ sender: Any) {
    self.delegate?.transferTokenViewControllerDidClickPendingTransaction()
  }

  @IBAction func tokenButtonPressed(_ sender: Any) {
    self.delegate?.transferTokenViewControllerDidClickTokenButton(self.selectedToken)
  }

  @IBAction func percentageButtonPressed(_ sender: UIButton) {
    let amount: BigInt = {
      let percent = sender.tag
      let balance: Balance = self.otherTokenBalances[self.selectedToken.address] ?? Balance(value: BigInt(0))
      return balance.value * BigInt(percent) / BigInt(100)
    }()
    self.amountTextField.text = amount.fullString(decimals: self.selectedToken.decimal)
    self.view.layoutIfNeeded()
    self.shouldUpdateEstimateGasUsed(sender)
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
    let qrcode = QRCodeReaderViewController()
    qrcode.delegate = self
    self.present(qrcode, animated: true, completion: nil)
  }

  @IBAction func gasPriceButtonPressed(_ sender: UIButton) {
    let gasPrice: Double = {
      if sender.tag == 1 { // Low
        return KNGasCoordinator.shared.lowKNGas
      }
      if sender.tag == 2 { // Standard
        return KNGasCoordinator.shared.standardKNGas
      }
      return KNGasCoordinator.shared.fastKNGas
    }()
    self.gasPriceTextField.text = "\(gasPrice)"
    self.updateTransactionFee()
  }

  @IBAction func advancedSwitchDidChange(_ sender: UISwitch) {
    if sender.isOn {
      self.advancedSettingsView.isHidden = false
      self.topPaddingConstraintForTransferButton.constant = kTransferButtonTopPaddingAdvancedSettingsOpen
    } else {
      self.advancedSettingsView.isHidden = true
      self.topPaddingConstraintForTransferButton.constant = UIDevice.isIphone5 ? kTransferButtonTopPaddingiPhone5 : kTransferButtonTopPaddingiPhone6
    }
    self.view.setNeedsUpdateConstraints()
  }

  @IBAction func transferButtonPressed(_ sender: Any) {
    self.validateData { [weak self] validateResult in
      switch validateResult {
      case .success(let trans):
        if let transaction = trans {
          self?.delegate?.transferTokenViewControllerDidClickTransfer(transaction: transaction)
        } //else {
          //self?.showInvalidDataToMakeTransactionAlert()
        //}
      case .failure(let error):
        //self?.displayError(error: error.error)
        self?.showErrorTopBannerMessage(with: "Error", message: error.description)
      }
    }
  }
}

// MARK: External update from coordinator
extension KNTransferTokenViewController {

  func coordinatorUpdateUSDBalance(usd: BigInt) {
    self.navigationItem.title = "$\(EtherNumberFormatter.short.string(from: usd))"
    self.view.layoutIfNeeded()
  }

  func coordinatorETHBalanceDidUpdate(balance: Balance) {
    self.otherTokenBalances[self.ethToken.address] = balance
    self.updateViewWhenBalancesDidChange()
  }

  func coordinatorOtherTokenBalanceDidUpdate(balances: [String: Balance]) {
    balances.forEach({ self.otherTokenBalances[$0.key] = $0.value })
    self.updateViewWhenBalancesDidChange()
  }

  func coordinatorSelectedTokenDidUpdate(_ token: KNToken) {
    if self.selectedToken == token { return }
    self.updateSelectedToken(token)
  }

  func coordinatorEstimateGasUsedDidUpdate(token: KNToken, amount: BigInt, estimate: BigInt) {
    if token != self.selectedToken { return }
    self.updateEstimateGasUsed(estimate)
  }

  func coordinatorTransferDidReturn(result: Result<String, AnyError>) {
    if case .failure(let error) =  result { self.displayError(error: error) }
  }
}

extension KNTransferTokenViewController {
  fileprivate func validateData(completion: (Result<UnconfirmedTransaction?, AnyError>) -> Void) {
    guard
      let amount = self.amountTextField.text?.fullBigInt(decimals: self.selectedToken.decimal),
      let balance = self.otherTokenBalances[self.selectedToken.address],
      amount <= balance.value, !amount.isZero else {
        self.showErrorTopBannerMessage(with: "Error", message: "Invalid amount to transfer".toBeLocalised())
        completion(.success(nil))
        return
    }

    guard let address = Address(string: self.addressTextField.text ?? "") else {
      self.showErrorTopBannerMessage(with: "Error", message: "Invalid address to transfer".toBeLocalised())
      completion(.success(nil))
      return
    }

    guard let gasPrice = self.gasPriceTextField.text?.fullBigInt(units: UnitConfiguration.gasPriceUnit) else {
      self.showErrorTopBannerMessage(with: "Error", message: "Invalid gas price to transfer".toBeLocalised())
      completion(.success(nil))
      return
    }

    let type: TransferType = {
      if self.selectedToken.isETH {
        return TransferType.ether(destination: address)
      }
      let tokenObject = TokenObject(
        contract: self.selectedToken.address,
        name: self.selectedToken.name,
        symbol: self.selectedToken.symbol,
        decimals: self.selectedToken.decimal,
        value: self.amountTextField.text ?? "0.0",
        isCustom: false,
        isDisabled: false)
      return TransferType.token(tokenObject)
    }()

    let transaction = UnconfirmedTransaction(
      transferType: type,
      value: amount,
      to: address,
      data: nil,
      gasLimit: self.lastEstimateGasUsed,
      gasPrice: gasPrice,
      nonce: .none
    )
    completion(.success(transaction))
  }
}

// MARK: TextField Delegation
extension KNTransferTokenViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if let text = textField.text, let int = EtherNumberFormatter.full.number(from: text), int.isZero {
      textField.text = ""
      self.updateViewTextFieldDidChange(textField)
    }
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.updateViewTextFieldDidChange(textField)
    return false
  }

  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.updateViewTextFieldDidChange(textField)
    return false
  }

  fileprivate func updateViewTextFieldDidChange(_ textField: UITextField) {
    if textField == self.addressTextField { return }
    if textField == self.gasPriceTextField { self.updateTransactionFee() }
    self.shouldUpdateEstimateGasUsed(textField)
  }
}

// MARK: QRCode Reader Delegation
extension KNTransferTokenViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) { self.addressTextField.text = result }
  }
}
