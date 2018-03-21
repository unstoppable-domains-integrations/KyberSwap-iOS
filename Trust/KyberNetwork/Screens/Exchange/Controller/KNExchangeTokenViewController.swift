// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import Result

protocol KNExchangeTokenViewControllerDelegate: class {
  func exchangeTokenAmountDidChange(source: KNToken, dest: KNToken, amount: BigInt)
  func exchangeTokenShouldUpdateEstimateGasUsed(exchangeTransaction: KNDraftExchangeTransaction)
  func exchangeTokenDidClickExchange(exchangeTransaction: KNDraftExchangeTransaction)
  func exchangeTokenUserDidClickSelectTokenButton(source: KNToken, dest: KNToken, isSource: Bool)
  func exchangeTokenUserDidClickExit()
  func exchangeTokenUserDidClickPendingTransactions()
}

class KNExchangeTokenViewController: KNBaseViewController {

  fileprivate let advancedSettingsHeight: CGFloat = 150
  fileprivate let exchangeButtonTopPaddingiPhone5: CGFloat = 40
  fileprivate let exchangeButtonTopPaddingAdvancedSettingsOpen: CGFloat = 210
  fileprivate let exchangeButtonTopPaddingiPhone6: CGFloat = 120
  fileprivate let exchangeButtonTopPaddingiPhone6Plus: CGFloat = 160

  fileprivate weak var delegate: KNExchangeTokenViewControllerDelegate?

  fileprivate let ethToken: KNToken = KNToken.ethToken()
  fileprivate let kncToken: KNToken = KNToken.kncToken()

  fileprivate var selectedFromToken: KNToken!
  fileprivate var selectedToToken: KNToken!

  fileprivate var isFocusingFromTokenAmount: Bool = true

  fileprivate var expectedRateTimer: Timer?
  fileprivate var ethBalance: Balance?
  fileprivate var otherTokenBalances: [String: Balance] = [:]

  fileprivate var lastEstimateGasUsed: BigInt = BigInt(0)
  fileprivate var estimateGasUsedTimer: Timer?

  fileprivate var expectedRate: BigInt = BigInt(0)
  fileprivate var slippageRate: BigInt = BigInt(0)
  fileprivate var userDidChangeMinRate: Bool = false

  @IBOutlet weak var scrollContainerView: UIScrollView!

  @IBOutlet weak var fromTokenLabel: UILabel!
  @IBOutlet weak var fromTokenButton: UIButton!
  @IBOutlet weak var fromTokenBalanceLabel: UILabel!
  @IBOutlet weak var amountFromTokenLabel: UILabel!
  @IBOutlet weak var amountFromTokenTextField: UITextField!

  @IBOutlet var percentageButtons: [UIButton]!

  @IBOutlet weak var toTokenLabel: UILabel!
  @IBOutlet weak var toTokenButton: UIButton!
  @IBOutlet weak var toTokenBalanceLabel: UILabel!

  @IBOutlet weak var amounToTokenLabel: UILabel!
  @IBOutlet weak var amountToTokenTextField: UITextField!

  @IBOutlet weak var heightForAdvancedSettingsView: NSLayoutConstraint!
  @IBOutlet weak var advancedSettingsView: UIView!
  @IBOutlet weak var minRateTextField: UITextField!
  @IBOutlet weak var gasPriceTextField: UITextField!
  @IBOutlet weak var lowGasPriceButton: UIButton!
  @IBOutlet weak var standardGasPriceButton: UIButton!
  @IBOutlet weak var fastGasPriceButton: UIButton!
  @IBOutlet weak var transactionFeeLabel: UILabel!

  @IBOutlet weak var topPaddingConstraintForExchangeButton: NSLayoutConstraint!
  @IBOutlet weak var advancedLabel: UILabel!
  @IBOutlet weak var advancedSwitch: UISwitch!
  @IBOutlet weak var expectedRateLabel: UILabel!
  @IBOutlet weak var exchangeButton: UIButton!

  init(delegate: KNExchangeTokenViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNExchangeTokenViewController.className, bundle: nil)
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
    self.expectedRateTimer?.invalidate()
    self.expectedRateTimer = nil
    self.expectedRateTimerShouldRepeat(nil)
    self.expectedRateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { [weak self] timer in
      self?.expectedRateTimerShouldRepeat(timer)
    })

    self.estimateGasUsedTimer?.invalidate()
    self.shouldUpdateEstimateGasUsed(nil)
    self.estimateGasUsedTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { [weak self] timer in
      self?.shouldUpdateEstimateGasUsed(timer)
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.expectedRateTimer?.invalidate()
    self.expectedRateTimer = nil
    self.estimateGasUsedTimer?.invalidate()
    self.estimateGasUsedTimer = nil
  }
}

// MARK: Setup view
extension KNExchangeTokenViewController {
  fileprivate func setupUI() {
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .plain, target: self, action: #selector(self.exitButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "pending_white_icon"), style: .plain, target: self, action: #selector(self.pendingTransactionsPressed(_:)))
    self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white

    self.setupInitialData()
    self.setupFromToken()
    self.setupToToken()
    self.setupAdvancedSettingsView()
    self.setupExchangeButton()
    self.view.updateConstraints()
  }

  fileprivate func setupInitialData() {
    self.selectedFromToken = self.ethToken
    self.selectedToToken = self.kncToken
    self.updateRates()
    self.lastEstimateGasUsed = KNGasConfiguration.exchangeTokensGasLimitDefault
  }

  fileprivate func setupFromToken() {
    self.fromTokenLabel.text = "From".toBeLocalised()
    self.fromTokenButton.rounded(color: UIColor.white, width: 1.0, radius: 10.0)

    self.amountFromTokenLabel.text = "Amount".toBeLocalised()
    self.amountFromTokenTextField.text = "0"
    self.amountFromTokenTextField.delegate = self

    for button in self.percentageButtons { button.rounded(color: .clear, width: 0, radius: 4.0) }
    self.updateFromTokenWhenTokenDidChange()
  }

  fileprivate func setupToToken() {
    self.toTokenLabel.text = "To".toBeLocalised()
    self.toTokenButton.rounded(color: UIColor.white, width: 1.0, radius: 10.0)

    self.amountToTokenTextField.text = "0"
    self.amountToTokenTextField.delegate = self

    self.updateToTokenWhenTokenDidChange()
  }

  fileprivate func setupAdvancedSettingsView() {
    self.minRateTextField.text = self.slippageRate.fullString(decimals: self.selectedToToken.decimal)
    self.minRateTextField.delegate = self

    self.gasPriceTextField.text = KNGasConfiguration.gasPriceDefault.fullString(units: UnitConfiguration.gasPriceUnit)
    self.gasPriceTextField.delegate = self

    self.lowGasPriceButton.setTitle("Low".toBeLocalised(), for: .normal)
    self.lowGasPriceButton.rounded(color: .clear, width: 0, radius: 4.0)

    self.standardGasPriceButton.setTitle("Standard".toBeLocalised(), for: .normal)
    self.standardGasPriceButton.rounded(color: .clear, width: 0, radius: 4.0)

    self.fastGasPriceButton.setTitle("Fast".toBeLocalised(), for: .normal)
    self.fastGasPriceButton.rounded(color: .clear, width: 0, radius: 4.0)

    let feeString: String = {
      let fee = BigInt(KNGasConfiguration.gasPriceDefault) * self.lastEstimateGasUsed
      return fee.shortString(units: UnitConfiguration.gasFeeUnit)
    }()

    self.transactionFeeLabel.text = "Transaction Fee: \(feeString) ETH".toBeLocalised()
    self.advancedLabel.text = "Advanced".toBeLocalised()

    self.advancedSettingsView.isHidden = true
  }

  fileprivate func setupExchangeButton() {
    let rateString = self.expectedRate.shortString(decimals: self.selectedToToken.decimal)
    self.expectedRateLabel.text = "1 \(self.selectedFromToken.symbol) = \(rateString) \(self.selectedToToken.symbol)"

    self.exchangeButton.setTitle("Exchange".uppercased().toBeLocalised(), for: .normal)
    self.exchangeButton.rounded(color: .clear, width: 0, radius: 5.0)

    self.topPaddingConstraintForExchangeButton.constant = UIDevice.isIphone5 ? exchangeButtonTopPaddingiPhone5 : exchangeButtonTopPaddingiPhone6
  }
}

// MARK: Update data
extension KNExchangeTokenViewController {
  fileprivate func updateFromToken(_ token: KNToken) {
    self.selectedFromToken = token
    self.userDidChangeMinRate = false
    self.updateRates()
    self.updateFromTokenWhenTokenDidChange()
  }

  fileprivate func updateToToken(_ token: KNToken) {
    self.selectedToToken = token
    self.userDidChangeMinRate = false
    self.updateRates()
    self.updateToTokenWhenTokenDidChange()
  }

  fileprivate func updateRates() {
    if let rate = KNRateCoordinator.shared.getRate(from: self.selectedFromToken, to: self.selectedToToken) {
      self.expectedRate = rate.rate
      self.slippageRate = rate.minRate
    } else {
      self.expectedRate = BigInt(0)
      self.slippageRate = BigInt(0)
    }
    self.updateViewWhenRatesDidChange()
  }

  fileprivate func updateEstimateGasUsed(_ estimateGas: BigInt) {
    self.lastEstimateGasUsed = estimateGas
    self.updateTransactionFee()
  }
}

// MARK: Update view
extension KNExchangeTokenViewController {
  fileprivate func updateFromTokenWhenTokenDidChange() {
    self.fromTokenButton.setImage(UIImage(named: self.selectedFromToken.icon), for: .normal)
    self.fromTokenButton.setTitle("\(self.selectedFromToken.display)", for: .normal)
    let balanceString = self.otherTokenBalances[self.selectedFromToken.address]?.amountShort ?? "0.0000"
    self.fromTokenBalanceLabel.text = "Balance: \(balanceString) \(self.selectedFromToken.symbol)".toBeLocalised()
    self.amountFromTokenTextField.text = "0"
    self.amountToTokenTextField.text = "0"
  }

  fileprivate func updateToTokenWhenTokenDidChange() {
    self.toTokenButton.setImage(UIImage(named: self.selectedToToken.icon), for: .normal)
    self.toTokenButton.setTitle("\(self.selectedToToken.display)", for: .normal)
    let balanceString = self.otherTokenBalances[self.selectedToToken.address]?.amountShort ?? "0.0000"
    self.toTokenBalanceLabel.text = "Balance: \(balanceString) \(self.selectedToToken.symbol)".toBeLocalised()
    self.amountFromTokenTextField.text = "0"
    self.amountToTokenTextField.text = "0"
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

  fileprivate func updateViewWhenRatesDidChange() {
    if !self.userDidChangeMinRate {
      self.minRateTextField.text = self.slippageRate.fullString(decimals: self.selectedToToken.decimal)
    }

    self.expectedRateLabel.text = "1 \(self.selectedFromToken.symbol) = \(self.expectedRate.shortString(decimals: self.selectedToToken.decimal)) \(self.selectedToToken.symbol)"
    if self.isFocusingFromTokenAmount {
      let expectedAmount: BigInt = {
        let amount = self.amountFromTokenTextField.text?.fullBigInt(decimals: self.selectedFromToken.decimal) ?? BigInt(0)
        return self.expectedRate * amount / BigInt(10).power(self.selectedToToken.decimal)
      }()
      self.amountToTokenTextField.text = expectedAmount.fullString(decimals: self.selectedToToken.decimal)
    } else {
      let amountSent: BigInt = {
        let expectedAmount = self.amountToTokenTextField.text?.fullBigInt(decimals: self.selectedToToken.decimal) ?? BigInt(0)
        return self.expectedRate.isZero ? BigInt(0) : expectedAmount * BigInt(10).power(self.selectedFromToken.decimal) / self.expectedRate
      }()
      self.amountFromTokenTextField.text = amountSent.fullString(decimals: self.selectedFromToken.decimal)
    }
  }

  fileprivate func updateViewWhenBalancesDidChange() {
    let sourceBalance = self.otherTokenBalances[self.selectedFromToken.address]?.amountShort ?? "0.0000"
    self.fromTokenBalanceLabel.text = "Balance: \(sourceBalance) \(self.selectedFromToken.symbol)".toBeLocalised()
    let destBalance = self.otherTokenBalances[self.selectedToToken.address]?.amountShort ?? "0.0000"
    self.toTokenBalanceLabel.text = "Balance: \(destBalance) \(self.selectedToToken.symbol)".toBeLocalised()
  }
}
// MARK: Update data from coordinator
extension KNExchangeTokenViewController {
  func updateBalance(usd: BigInt, eth: BigInt) {
    self.navigationItem.title = "$\(EtherNumberFormatter.short.string(from: usd))"
    self.view.layoutIfNeeded()
  }

  func updateSelectedToken(_ token: KNToken, isSource: Bool) {
    if isSource {
      if self.selectedFromToken == token { return }
      self.updateFromToken(token)
      self.updateToToken(token.isETH ? self.kncToken : self.ethToken)
    } else {
      if self.selectedToToken == token { return }
      self.updateToToken(token)
      self.updateFromToken(token.isETH ? self.kncToken : self.ethToken)
    }
  }

  func ethBalanceDidUpdate(balance: Balance) {
    self.ethBalance = balance
    self.otherTokenBalances[self.ethToken.address] = balance
    self.updateViewWhenBalancesDidChange()
  }

  func otherTokenBalanceDidUpdate(balances: [String: Balance]) {
    self.otherTokenBalances = balances
    self.otherTokenBalances[self.ethToken.address] = self.ethBalance
    self.updateViewWhenBalancesDidChange()
  }

  func updateEstimateRateDidChange(source: KNToken, dest: KNToken, amount: BigInt, expectedRate: BigInt, slippageRate: BigInt) {
    if source != self.selectedFromToken || dest != self.selectedToToken { return }
    self.expectedRate = expectedRate
    self.slippageRate = slippageRate
    self.updateViewWhenRatesDidChange()
  }

  func updateEstimateGasUsed(source: KNToken, dest: KNToken, amount: BigInt, estimate: BigInt) {
    if source != self.selectedFromToken || dest != self.selectedToToken { return }
    self.updateEstimateGasUsed(estimate)
  }

  func exchangeTokenDidReturn(result: Result<String, AnyError>) {
    if case .failure(let error) =  result {
      self.displayError(error: error)
    }
  }
}

// MARK: Helpers & Buttons handlers
extension KNExchangeTokenViewController {
  fileprivate func validateData(completion: (Result<KNDraftExchangeTransaction?, AnyError>) -> Void) {
    guard
      let amount = self.amountFromTokenTextField.text?.fullBigInt(decimals: self.selectedFromToken.decimal),
      let balance = self.otherTokenBalances[self.selectedFromToken.address],
      amount <= balance.value, !amount.isZero else {
      completion(.success(nil))
      return
    }
    guard let gasPrice = self.gasPriceTextField.text?.fullBigInt(units: UnitConfiguration.gasPriceUnit) else {
      completion(.success(nil))
      return
    }
    if self.advancedSwitch.isOn && (self.minRateTextField.text ?? "0").fullBigInt(decimals: self.selectedToToken.decimal) == nil {
      completion(.success(nil))
      return
    }
    let minRate: BigInt? = self.advancedSwitch.isOn ? self.minRateTextField.text?.fullBigInt(decimals: self.selectedToToken.decimal) : .none
    let exchange = KNDraftExchangeTransaction(
      from: self.selectedFromToken,
      to: self.selectedToToken,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: self.expectedRate,
      minRate: minRate,
      gasPrice: gasPrice,
      gasLimit: self.lastEstimateGasUsed
    )
    completion(.success(exchange))
  }

  fileprivate func shouldUpdateEstimateGasUsed(_ sender: Any?) {
    let amount = self.amountFromTokenTextField.text?.fullBigInt(decimals: self.selectedFromToken.decimal) ?? BigInt(0)
    let exchange = KNDraftExchangeTransaction(
      from: self.selectedFromToken,
      to: self.selectedToToken,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: self.expectedRate,
      minRate: .none,
      gasPrice: .none,
      gasLimit: .none
    )
    self.delegate?.exchangeTokenShouldUpdateEstimateGasUsed(exchangeTransaction: exchange)
  }

  @objc func expectedRateTimerShouldRepeat(_ sender: Any?) {
    let amount = self.amountFromTokenTextField.text?.fullBigInt(decimals: self.selectedFromToken.decimal) ?? BigInt(0)
    self.delegate?.exchangeTokenAmountDidChange(
      source: self.selectedFromToken,
      dest: self.selectedToToken,
      amount: amount
    )
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.exchangeTokenUserDidClickExit()
  }

  @objc func pendingTransactionsPressed(_ sender: Any) {
    self.delegate?.exchangeTokenUserDidClickPendingTransactions()
  }

  @IBAction func fromTokenButtonPressed(_ sender: Any) {
    self.delegate?.exchangeTokenUserDidClickSelectTokenButton(
      source: self.selectedFromToken,
      dest: self.selectedToToken,
      isSource: true
    )
  }

  @IBAction func percentageButtonPressed(_ sender: UIButton) {
    self.isFocusingFromTokenAmount = true
    let amount: BigInt = {
      let percent = sender.tag
      let balance: Balance = self.otherTokenBalances[self.selectedFromToken.address] ?? Balance(value: BigInt(0))
      return balance.value * BigInt(percent) / BigInt(100)
    }()
    self.amountFromTokenTextField.text = amount.fullString(decimals: self.selectedFromToken.decimal)
    self.view.layoutIfNeeded()
    self.expectedRateTimerShouldRepeat(sender)
    self.shouldUpdateEstimateGasUsed(sender)
  }

  @IBAction func toTokenButtonPressed(_ sender: Any) {
    self.delegate?.exchangeTokenUserDidClickSelectTokenButton(
      source: self.selectedFromToken,
      dest: self.selectedToToken,
      isSource: false
    )
  }

  @IBAction func advancedSwitchDidChange(_ sender: Any) {
    if self.advancedSwitch.isOn {
      self.advancedSettingsView.isHidden = false
      self.topPaddingConstraintForExchangeButton.constant = exchangeButtonTopPaddingAdvancedSettingsOpen
    } else {
      self.advancedSettingsView.isHidden = true
      self.topPaddingConstraintForExchangeButton.constant = UIDevice.isIphone5 ? exchangeButtonTopPaddingiPhone5 : exchangeButtonTopPaddingiPhone6
    }
    self.view.updateConstraints()
  }

  @IBAction func lowGasPriceButtonPressed(_ sender: Any) {
    self.gasPriceTextField.text = "\(KNGasCoordinator.shared.lowKNGas)"
    self.updateTransactionFee()
  }

  @IBAction func standardGasPriceButtonPressed(_ sender: Any) {
    self.gasPriceTextField.text = "\(KNGasCoordinator.shared.standardKNGas)"
    self.updateTransactionFee()
  }

  @IBAction func fastGasPriceButtonPressed(_ sender: Any) {
    self.gasPriceTextField.text = "\(KNGasCoordinator.shared.fastKNGas)"
    self.updateTransactionFee()
  }

  @IBAction func exchangeButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.validateData { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let exchangeTransaction):
        if let exchange = exchangeTransaction {
          self.delegate?.exchangeTokenDidClickExchange(exchangeTransaction: exchange)
        } else {
          self.showInvalidDataToMakeTransactionAlert()
        }
      case .failure(let error):
        self.displayError(error: error)
      }
    }
  }
}

// MARK: Delegations
extension KNExchangeTokenViewController: UITextFieldDelegate {

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
    if textField == self.amountFromTokenTextField {
      self.isFocusingFromTokenAmount = true
    } else if textField == self.amountToTokenTextField {
      self.isFocusingFromTokenAmount = false
    } else if textField == self.gasPriceTextField {
      self.updateTransactionFee()
    } else if textField == self.minRateTextField {
      self.userDidChangeMinRate = true
    }
    self.shouldUpdateEstimateGasUsed(textField)
    self.expectedRateTimerShouldRepeat(textField)
  }
}
