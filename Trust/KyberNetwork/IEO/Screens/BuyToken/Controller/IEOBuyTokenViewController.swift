// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum IEOBuyTokenViewEvent {
  case close
  case selectBuyToken
  case selectIEO
  case selectSetGasPrice(gasPrice: BigInt, gasLimit: BigInt)
  case buy(transaction: IEODraftTransaction)
}

protocol IEOBuyTokenViewControllerDelegate: class {
  func ieoBuyTokenViewController(_ controller: IEOBuyTokenViewController, run event: IEOBuyTokenViewEvent)
}

class IEOBuyTokenViewModel {
  fileprivate(set) var walletObject: KNWalletObject

  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: IEOObject

  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true

  fileprivate(set) var estRate: BigInt?

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .fast
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas

  fileprivate(set) var estimateGasLimit: BigInt = KNGasConfiguration.transferETHBuyTokenSaleGasLimitDefault

  init(from: TokenObject = KNSupportedTokenStorage.shared.ethToken,
       to: IEOObject,
       walletObject: KNWalletObject
    ) {
    self.walletObject = walletObject
    self.from = from
    self.to = to
    self.estRate = self.to.rate.fullBigInt(decimals: self.to.tokenDecimals)
  }

  // MARK: From Token
  var amountFromBigInt: BigInt {
    return self.amountFrom.fullBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var fromTokenIconName: String {
    return self.from.icon
  }

  var fromTokenBtnTitle: String {
    return self.from.symbol
  }

  // when user wants to fix received amount
  var expectedExchangeAmountText: String {
    guard let rate = self.estRate, !self.amountToBigInt.isZero else {
      return ""
    }
    let expectedExchange: BigInt = {
      let amount = self.amountTo.fullBigInt(decimals: self.to.tokenDecimals) ?? BigInt(0)
      return amount * BigInt(10).power(self.from.decimals) / rate
    }()
    return expectedExchange.string(decimals: self.from.decimals, minFractionDigits: 1, maxFractionDigits: 4)
  }

  // MARK: To Token
  var amountToBigInt: BigInt {
    return self.amountTo.fullBigInt(decimals: self.to.tokenDecimals) ?? BigInt(0)
  }

  var toTokenBtnTitle: String {
    return self.to.tokenSymbol
  }

  var toTokenIconName: String {
    return self.to.icon
  }

  var amountTextFieldColor: UIColor {
    if self.amountFromBigInt > (self.balance?.value ?? BigInt(0)) || self.amountFromBigInt.isZero {
      return UIColor.red
    }
    return UIColor(hex: "31CB9E")
  }

  var expectedReceivedAmountText: String {
    guard let rate = self.estRate, !self.amountFromBigInt.isZero else {
      return ""
    }
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return rate * amount / BigInt(10).power(self.from.decimals)
    }()
    return expectedAmount.string(decimals: self.to.tokenDecimals, minFractionDigits: 1, maxFractionDigits: 4)
  }

  func tokenButtonAttributedText(isSource: Bool) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.medium),
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
      ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular),
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
      ]
    let symbol = isSource ? self.from.symbol : self.to.tokenSymbol
    let name = isSource ? self.from.name : self.to.tokenName
    attributedString.append(NSAttributedString(string: symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(name)", attributes: nameAttributes))
    return attributedString
  }

  // MARK: Balance
  var balanceText: String {
    let bal: BigInt = self.balance?.value ?? BigInt(0)
    return "\(bal.shortString(decimals: self.from.decimals))"
  }

  var balanceTextString: String {
    return "\(self.from.symbol) Balance"
  }

  // MARK: Rate
  var exchangeRateText: String {
    let rateString: String = self.estRate?.string(decimals: self.to.tokenDecimals, minFractionDigits: 2, maxFractionDigits: 9) ?? "---"
    return "\(rateString)"
  }

  // MARK: Gas Price
  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }

  // MARK: Verify data
  // Amount should > 0 and <= balance
  var isAmountValid: Bool {
    if self.amountFromBigInt <= BigInt(0) { return false }
    if self.amountFromBigInt > self.balance?.value ?? BigInt(0) { return false }
    return true
  }

  // rate should not be nil and greater than zero
  var isRateValid: Bool {
    if self.estRate == nil || self.estRate?.isZero == true { return false }
    return true
  }

  var walletButtonTitle: String {
    return "\(self.walletObject.name) - \(self.walletObject.address.prefix(7))....\(self.walletObject.address.suffix(5))"
  }

  var transaction: IEODraftTransaction {
    return IEODraftTransaction(
      token: self.from,
      ieo: self.to,
      amount: self.amountFromBigInt,
      wallet: self.walletObject,
      gasPrice: self.gasPrice,
      gasLimit: self.estimateGasLimit,
      estRate: self.estRate
    )
  }

  // MARK: Update data
  func updateWallet(_ walletObject: KNWalletObject) {
    self.walletObject = walletObject

    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true

    self.balances = [:]
    self.balance = nil

    self.estRate = nil
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
  }

  func updateSelectedToken(_ token: TokenObject) {
    self.amountFrom = ""
    self.amountTo = ""
    self.estRate = nil
    self.estimateGasLimit = KNGasConfiguration.exchangeTokensGasLimitDefault
    self.balance = self.balances[self.from.contract]
  }

  func updateFocusingField(_ isSource: Bool) {
    self.isFocusingFromAmount = isSource
  }

  func updateAmount(_ amount: String, isSource: Bool) {
    if isSource {
      self.amountFrom = amount
    } else {
      self.amountTo = amount
    }
  }

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      self.balance = bal
    }
  }

  func updateBalance(_ balance: Balance) {
    self.balance = balance
  }

  func updateEstimatedRate(_ rate: BigInt) {
    self.estRate = rate
  }

  func updateEstimateGasLimit(_ gasLimit: BigInt) {
    self.estimateGasLimit = gasLimit
  }

  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    default: break
    }
  }

  // update when set gas price
  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
    self.selectedGasPriceType = .custom
  }
}

class IEOBuyTokenViewController: KNBaseViewController {

  @IBOutlet weak var tokenContainerView: UIView!
  @IBOutlet weak var fromTokenButton: UIButton!
  @IBOutlet weak var buyAmountTextField: UITextField!

  @IBOutlet weak var toIEOButton: UIButton!
  @IBOutlet weak var receivedAmountTextField: UITextField!

  @IBOutlet weak var balanceTextLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var rateLabel: UILabel!

  @IBOutlet weak var gasPriceButton: UIButton!
  @IBOutlet weak var gasTextLabel: UILabel!
  @IBOutlet weak var gasPriceSegmentedControl: KNCustomSegmentedControl!

  @IBOutlet weak var selectWalletButton: UIButton!

  fileprivate var viewModel: IEOBuyTokenViewModel
  weak var delegate: IEOBuyTokenViewControllerDelegate?

  fileprivate var balanceTimer: Timer?

  init(viewModel: IEOBuyTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: IEOBuyTokenViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  lazy var toolBar: KNCustomToolbar = {
    return KNCustomToolbar(
      leftBtnTitle: "Exchange All",
      rightBtnTitle: "Done",
      delegate: self)
  }()

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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.balanceTimer?.invalidate()
    self.reloadDataFromNode()
    self.balanceTimer = Timer.scheduledTimer(withTimeInterval: KNLoadingInterval.defaultLoadingInterval, repeats: true, block: { [weak self] _ in
      guard let `self` = self else { return }
      self.reloadDataFromNode()
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.balanceTimer?.invalidate()
  }

  fileprivate func setupUI() {
    self.setupTokenView()
    self.setupGasPriceView()
    self.setupSelectWallet()
  }

  fileprivate func setupTokenView() {
    self.buyAmountTextField.text = ""
    self.receivedAmountTextField.text = ""

    self.receivedAmountTextField.delegate = self
    self.buyAmountTextField.delegate = self

    self.fromTokenButton.setAttributedTitle(self.viewModel.tokenButtonAttributedText(isSource: true), for: .normal)
    self.toIEOButton.setAttributedTitle(self.viewModel.tokenButtonAttributedText(isSource: false), for: .normal)

    self.balanceTextLabel.text = self.viewModel.balanceTextString
    self.tokenBalanceLabel.text = self.viewModel.balanceText

    self.rateLabel.text = self.viewModel.exchangeRateText
  }

  fileprivate func setupGasPriceView() {
    self.gasTextLabel.isHidden = true
    self.gasPriceSegmentedControl.isHidden = true
    self.gasPriceSegmentedControl.addTarget(self, action: #selector(self.gasPriceSegmentedControlDidTouch(_:)), for: .touchDown)
  }

  fileprivate func setupSelectWallet() {
    self.selectWalletButton.rounded(radius: 4)
    self.selectWalletButton.setTitle(self.viewModel.walletButtonTitle, for: .normal)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.ieoBuyTokenViewController(self, run: .close)
  }

  @IBAction func fromTokenButtonPressed(_ sender: Any) {
    self.showWarningTopBannerMessage(with: "", message: "We will support this feature soon")
    self.delegate?.ieoBuyTokenViewController(self, run: .selectBuyToken)
  }

  @IBAction func toIEOButtonPressed(_ sender: Any) {
    self.showWarningTopBannerMessage(with: "", message: "We will support change IEO from here soon")
    self.delegate?.ieoBuyTokenViewController(self, run: .selectIEO)
  }

  @IBAction func gasPriceButtonPressed(_ sender: Any) {
    UIView.animate(withDuration: 0.3) {
      self.gasPriceSegmentedControl.isHidden = !self.gasPriceSegmentedControl.isHidden
      self.gasTextLabel.isHidden = !self.gasTextLabel.isHidden
      self.gasPriceButton.setImage(
        UIImage(named: self.gasTextLabel.isHidden ? "expand_icon" : "collapse_icon"), for: .normal)
    }
  }

  @IBAction func selectWalletButtonPressed(_ sender: Any) {
    self.showWarningTopBannerMessage(with: "", message: "Unsupported feature")
  }

  @objc func gasPriceSegmentedControlDidTouch(_ sender: Any) {
    let selectedId = self.gasPriceSegmentedControl.selectedSegmentIndex
    if selectedId == 3 {
      // custom gas price
      let event = IEOBuyTokenViewEvent.selectSetGasPrice(
        gasPrice: self.viewModel.gasPrice,
        gasLimit: self.viewModel.estimateGasLimit
      )
      self.delegate?.ieoBuyTokenViewController(self, run: event)
    } else {
      self.viewModel.updateSelectedGasPriceType(KNSelectedGasPriceType(rawValue: selectedId) ?? .fast)
    }
  }

  @IBAction func buyButtonPressed(_ sender: Any) {
    let amount = self.viewModel.amountFromBigInt
    guard self.viewModel.isAmountValid else {
      self.showWarningTopBannerMessage(with: "Invalid Amount", message: "Please input a valid amount to buy")
      return
    }
    guard let rate = self.viewModel.estRate else {
      self.showWarningTopBannerMessage(with: "Invalid Rate", message: "We could not update rate from node")
      return
    }
    let transaction = IEODraftTransaction(
      token: self.viewModel.from,
      ieo: self.viewModel.to,
      amount: amount,
      wallet: self.viewModel.walletObject,
      gasPrice: self.viewModel.gasPrice,
      gasLimit: self.viewModel.estimateGasLimit,
      estRate: rate
    )
    self.delegate?.ieoBuyTokenViewController(self, run: .buy(transaction: transaction))
  }

  @objc func keyboardExchangeAllButtonPressed(_ sender: Any) {
    self.buyAmountTextField.text = self.viewModel.balance?.amountFull ?? ""
    self.viewModel.updateFocusingField(true)
    self.viewModel.updateAmount(self.buyAmountTextField.text ?? "", isSource: true)
    self.tokenBalanceLabel.text = self.viewModel.balanceText
    self.rateLabel.text = self.viewModel.exchangeRateText
    self.updateViewAmountDidChange()
    self.view.endEditing(true)
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: Any) {
    self.delegate?.ieoBuyTokenViewController(self, run: .close)
  }

  fileprivate func reloadDataFromNode() {
    IEOProvider.shared.getETHBalance(
      for: self.viewModel.walletObject.address,
      completion: { [weak self] result in
        guard let `self` = self else { return }
        // Don't care if it is failed
        if case .success(let bal) = result {
          self.viewModel.updateBalance(bal)
          self.tokenBalanceLabel.text = self.viewModel.balanceText
          if !self.buyAmountTextField.isEditing {
            self.buyAmountTextField.textColor = self.viewModel.amountTextFieldColor
          }
        }
    })
//    IEOProvider.shared.getEstimateGasLimit(
//    for: self.viewModel.transaction) { [weak self] result in
//      guard let `self` = self else { return }
//      // Don't care if it is failed
//      if case .success(let gasLimit) = result {
//        self.viewModel.updateEstimateGasLimit(gasLimit)
//      }
//    }
  }
}

extension IEOBuyTokenViewController {
  func coordinatorBuyTokenDidUpdateGasPrice(_ gasPrice: BigInt?) {
    if let gasPrice = gasPrice {
      self.viewModel.updateGasPrice(gasPrice)
    }
    self.gasPriceSegmentedControl.selectedSegmentIndex = self.viewModel.selectedGasPriceType.rawValue
    self.view.layoutIfNeeded()
  }

  func coordinatorDidUpdateEstRate(for ieo: IEOObject, rate: BigInt) {
    if ieo.contract == self.viewModel.to.contract {
      self.viewModel.updateEstimatedRate(rate)
      self.rateLabel.text = self.viewModel.exchangeRateText
      self.updateViewAmountDidChange()
    }
  }
}

extension IEOBuyTokenViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateFocusingField(textField == self.buyAmountTextField)
    self.viewModel.updateAmount("", isSource: textField == self.buyAmountTextField)
    self.updateViewAmountDidChange()
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    if text.isEmpty || Double(text) != nil {
      textField.text = text
      self.viewModel.updateFocusingField(textField == self.buyAmountTextField)
      self.viewModel.updateAmount(text, isSource: textField == self.buyAmountTextField)
      self.updateViewAmountDidChange()
    }
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.updateFocusingField(textField == self.buyAmountTextField)
    self.buyAmountTextField.textColor = UIColor(hex: "31CB9E")
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.buyAmountTextField.textColor = self.viewModel.amountTextFieldColor
  }

  fileprivate func updateViewAmountDidChange() {
    if self.viewModel.isFocusingFromAmount {
      self.receivedAmountTextField.text = self.viewModel.expectedReceivedAmountText
      self.viewModel.updateAmount(self.receivedAmountTextField.text ?? "", isSource: false)
    } else {
      self.buyAmountTextField.text = self.viewModel.expectedExchangeAmountText
      self.viewModel.updateAmount(self.buyAmountTextField.text ?? "", isSource: true)
    }
  }
}

// MARK: Toolbar delegate
extension IEOBuyTokenViewController: KNCustomToolbarDelegate {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardExchangeAllButtonPressed(toolbar)
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}
