// Copyright SIX DAY LLC. All rights reserved.
import UIKit
import BigInt
import Result

enum KNExchangeTabViewEvent {
  case searchToken(from: TokenObject, to: TokenObject, isSource: Bool)
  case estimateRate(from: TokenObject, to: TokenObject, amount: BigInt)
  case estimateGas(from: TokenObject, to: TokenObject, amount: BigInt, gasPrice: BigInt)
  case setGasPrice(gasPrice: BigInt, gasLimit: BigInt)
  case exchange(data: KNDraftExchangeTransaction)
  case showQRCode
}

protocol KNExchangeTabViewControllerDelegate: class {
  func exchangeTabViewController(_ controller: KNExchangeTabViewController, run event: KNExchangeTabViewEvent)
  func exchangeTabViewController(_ controller: KNExchangeTabViewController, run event: KNBalanceTabHamburgerMenuViewEvent)
}

class KNExchangeTabViewController: KNBaseViewController {

  fileprivate var isViewSetup: Bool = false
  @IBOutlet weak var walletHeaderView: KNWalletHeaderView!

  @IBOutlet weak var dataContainerView: UIView!
  @IBOutlet weak var fromTokenButton: UIButton!

  @IBOutlet weak var balanceTextLabel: UILabel! // "\(symbol) balance"
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var toTokenButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!

  @IBOutlet weak var fromAmountTextField: UITextField!
  @IBOutlet weak var toAmountTextField: UITextField!

  @IBOutlet weak var exchangeRateLabel: UILabel!

  @IBOutlet weak var gasPriceOptionButton: UIButton!
  @IBOutlet weak var gasPriceSegmentedControl: KNCustomSegmentedControl!
  @IBOutlet weak var gasTextLabel: UILabel!

  fileprivate var viewModel: KNExchangeTabViewModel
  weak var delegate: KNExchangeTabViewControllerDelegate?

  fileprivate var estRateTimer: Timer?
  fileprivate var estGasLimitTimer: Timer?

  lazy var hamburgerMenu: KNBalanceTabHamburgerMenuViewController = {
    let viewModel = KNBalanceTabHamburgerMenuViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
    let hamburgerVC = KNBalanceTabHamburgerMenuViewController(viewModel: viewModel)
    hamburgerVC.view.frame = self.view.bounds
    self.view.addSubview(hamburgerVC.view)
    self.addChildViewController(hamburgerVC)
    hamburgerVC.didMove(toParentViewController: self)
    hamburgerVC.delegate = self
    return hamburgerVC
  }()

  lazy var toolBar: KNCustomToolbar = {
    return KNCustomToolbar(
      leftBtnTitle: "Exchange All",
      rightBtnTitle: "Done",
      delegate: self)
  }()

  init(viewModel: KNExchangeTabViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNExchangeTabViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.dataContainerView.addShadow(
      color: UIColor.black,
      offset: CGSize(width: 0, height: 8),
      opacity: 0.11,
      radius: 14
    )
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // start update est rate
    self.estRateTimer?.invalidate()
    self.updateEstimatedRate()
    self.estRateTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
      self?.updateEstimatedRate()
    })

    // start update est gas limit
    self.estGasLimitTimer?.invalidate()
    self.updateEstimatedGasLimit()
    self.estGasLimitTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
        self?.updateEstimatedGasLimit()
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.estRateTimer?.invalidate()
    self.estRateTimer = nil
    self.estGasLimitTimer?.invalidate()
    self.estGasLimitTimer = nil
  }

  fileprivate func setupUI() {
    self.setupWalletHeaderView()
    self.setupTokensView()
    self.setupHamburgerMenu()
  }

  fileprivate func setupWalletHeaderView() {
    self.walletHeaderView.delegate = self
    self.walletHeaderView.updateView(with: self.viewModel.walletObject)
  }

  fileprivate func setupTokensView() {
    self.dataContainerView.rounded(color: UIColor(hex: "979797").withAlphaComponent(0.15), width: 1, radius: 4.0)
    self.fromTokenButton.titleLabel?.numberOfLines = 2
    self.fromTokenButton.titleLabel?.lineBreakMode = .byWordWrapping
    self.toTokenButton.titleLabel?.numberOfLines = 2
    self.toTokenButton.titleLabel?.lineBreakMode = .byWordWrapping
    self.toTokenButton.semanticContentAttribute = .forceRightToLeft

    self.fromAmountTextField.text = ""
    self.fromAmountTextField.adjustsFontSizeToFitWidth = true
    self.fromAmountTextField.inputAccessoryView = self.toolBar
    self.fromAmountTextField.delegate = self
    self.fromAmountTextField.underlined(
      lineHeight: 0.25,
      color: UIColor(hex: "e8ebed"),
      isAlignLeft: true,
      width: 100,
      bottom: 0
    )
    self.viewModel.updateAmount("", isSource: true)
    self.balanceTextLabel.text = self.viewModel.balanceTextString

    self.toAmountTextField.text = ""
    self.toAmountTextField.adjustsFontSizeToFitWidth = true
    self.toAmountTextField.inputAccessoryView = self.toolBar
    self.toAmountTextField.delegate = self
    self.toAmountTextField.underlined(
      lineHeight: 0.25,
      color: UIColor(hex: "e8ebed"),
      isAlignLeft: false,
      width: 100,
      bottom: 0
    )
    self.viewModel.updateAmount("", isSource: false)

    self.gasPriceOptionButton.setImage(UIImage(named: "expand_icon"), for: .normal)
    self.gasPriceSegmentedControl.selectedSegmentIndex = 0 // select fast option
    self.gasPriceSegmentedControl.addTarget(self, action: #selector(self.gasPriceSegmentedControlDidTouch(_:)), for: .touchDown)
    self.gasPriceSegmentedControl.isHidden = true
    self.gasTextLabel.isHidden = true

    self.updateTokensView()
  }

  fileprivate func setupHamburgerMenu() {
    self.hamburgerMenu.hideMenu(animated: false)
  }

  @IBAction func fromTokenButtonPressed(_ sender: UIButton) {
    let event = KNExchangeTabViewEvent.searchToken(
      from: self.viewModel.from,
      to: self.viewModel.to,
      isSource: true
    )
    self.delegate?.exchangeTabViewController(self, run: event)
  }

  @IBAction func toTokenButtonPressed(_ sender: UIButton) {
    let event = KNExchangeTabViewEvent.searchToken(
      from: self.viewModel.from,
      to: self.viewModel.to,
      isSource: false
    )
    self.delegate?.exchangeTabViewController(self, run: event)
  }

  @IBAction func swapButtonPressed(_ sender: UIButton) {
    self.viewModel.swapTokens()
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.updateTokensView()
  }

  @IBAction func gasPriceButtonPressed(_ sender: Any) {
    UIView.animate(withDuration: 0.3) {
      self.gasPriceSegmentedControl.isHidden = !self.gasPriceSegmentedControl.isHidden
      self.gasTextLabel.isHidden = !self.gasTextLabel.isHidden
      self.gasPriceOptionButton.setImage(
        UIImage(named: self.gasTextLabel.isHidden ? "expand_icon" : "collapse_icon"), for: .normal)
    }
  }

  @objc func gasPriceSegmentedControlDidTouch(_ sender: Any) {
    let selectedId = self.gasPriceSegmentedControl.selectedSegmentIndex
    if selectedId == 3 {
      // custom gas price
      let event = KNExchangeTabViewEvent.setGasPrice(
        gasPrice: self.viewModel.gasPrice,
        gasLimit: self.viewModel.estimateGasLimit
      )
      self.delegate?.exchangeTabViewController(self, run: event)
    } else {
      self.viewModel.updateSelectedGasPriceType(KNSelectedGasPriceType(rawValue: selectedId) ?? .fast)
    }
  }

  /*
    Exchange token pressed
    - check amount valid (> 0 and <= balance)
    - check rate is valie (not zero)
    - (Temp) either from or to must be ETH
    - send exchange tx to coordinator for preparing trade
   */
  @IBAction func exchangeButtonPressed(_ sender: UIButton) {
    // Check data
    guard !self.viewModel.isAmountTooSmall else {
      self.showWarningTopBannerMessage(with: "Invalid amount", message: "Amount too small to perform exchange, minumum equivalent to 0.001 ETH")
      return
    }
    guard !self.viewModel.isAmountTooBig else {
      self.showWarningTopBannerMessage(with: "Invalid amount", message: "Amount too big to perform exchange")
      return
    }
    guard let rate = self.viewModel.estRate, self.viewModel.isRateValid else {
      self.showWarningTopBannerMessage(with: "Invalid rate", message: "Please wait for estimated rate to exchange")
      return
    }
    // TODO: This is not true in case we could exchange token/token
    guard self.viewModel.from != self.viewModel.to else {
      self.showWarningTopBannerMessage(with: "Invalid tokens", message: "Can not exchange the same token")
      return
    }
    let amount: BigInt = {
      if self.viewModel.isFocusingFromAmount { return self.viewModel.amountFromBigInt }
      let expectedExchange: BigInt = {
        let amount = self.viewModel.amountToBigInt
        return amount * BigInt(10).power(self.viewModel.from.decimals) / rate
      }()
      return expectedExchange
    }()
    let exchange = KNDraftExchangeTransaction(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: rate,
      minRate: self.viewModel.slippageRate,
      gasPrice: self.viewModel.gasPrice,
      gasLimit: self.viewModel.estimateGasLimit,
      expectedReceivedString: self.viewModel.amountTo
    )
    self.delegate?.exchangeTabViewController(self, run: .exchange(data: exchange))
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    self.hamburgerMenu.gestureScreenEdgePanAction(sender)
  }

  @objc func keyboardExchangeAllButtonPressed(_ sender: Any) {
    self.fromAmountTextField.text = self.viewModel.allFromTokenBalanceString
    self.viewModel.updateFocusingField(true)
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    self.updateTokensView()
    self.updateViewAmountDidChange()
    self.view.endEditing(true)
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
  }

  func coordinatorUpdateGasPriceCached() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
  }

  fileprivate func updateEstimatedRate() {
    let event = KNExchangeTabViewEvent.estimateRate(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: self.viewModel.amountFromBigInt
    )
    self.delegate?.exchangeTabViewController(self, run: event)
  }

  fileprivate func updateEstimatedGasLimit() {
    let event = KNExchangeTabViewEvent.estimateGas(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: self.viewModel.amountFromBigInt,
      gasPrice: self.viewModel.gasPrice
    )
    self.delegate?.exchangeTabViewController(self, run: event)
  }
}

// MARK: Update UIs
extension KNExchangeTabViewController {
  /*
    Update tokens view when either from or to tokens changed
      - updatedFrom: true if from token is changed
      - updatedTo: true if to token is changed
   */
  func updateTokensView(updatedFrom: Bool = true, updatedTo: Bool = true) {
    if updatedFrom {
      self.fromTokenButton.setAttributedTitle(
        self.viewModel.tokenButtonAttributedText(isSource: true),
        for: .normal
      )
      self.fromTokenButton.setTokenImage(
        token: self.viewModel.from,
        size: self.viewModel.defaultTokenIconImg?.size
      )
      self.balanceTextLabel.text = self.viewModel.balanceTextString
    }
    if updatedTo {
      self.toTokenButton.setAttributedTitle(
        self.viewModel.tokenButtonAttributedText(isSource: false),
        for: .normal
      )
      self.toTokenButton.setTokenImage(
        token: self.viewModel.to,
        size: self.viewModel.defaultTokenIconImg?.size
      )
    }
    self.viewModel.updateEstimatedRateFromCachedIfNeeded()
    // call update est rate from node
    self.updateEstimatedRate()
    self.balanceLabel.text = self.viewModel.balanceText
    self.exchangeRateLabel.text = self.viewModel.exchangeRateText
    if !self.fromAmountTextField.isFirstResponder {
      self.fromAmountTextField.textColor = self.viewModel.amountTextFieldColor
    }
    self.view.layoutIfNeeded()
  }

}

// MARK: Update from coordinator
extension KNExchangeTabViewController {
  /*
   Update new session when current wallet is changed, update all UIs
   */
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.updateWallet(wallet)
    self.walletHeaderView.updateView(with: self.viewModel.walletObject)
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.updateTokensView()
    self.updateViewAmountDidChange()
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
  }

  func coordinatorUpdateWalletObjects() {
    self.viewModel.updateWalletObject()
    self.walletHeaderView.updateView(with: self.viewModel.walletObject)
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.balanceLabel.text = self.viewModel.balanceText
    if !self.fromAmountTextField.isFirstResponder {
      self.fromAmountTextField.textColor = self.viewModel.amountTextFieldColor
    }
    self.view.layoutIfNeeded()
  }

  /*
    Update estimate rate, check if the from, to, amount are all the same as current value in the model
    Update UIs according to new values
   */
  func coordinatorDidUpdateEstimateRate(from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) {
    self.viewModel.updateExchangeRate(
      for: from,
      to: to,
      amount: amount,
      rate: rate,
      slippageRate: slippageRate
    )
    self.exchangeRateLabel.text = self.viewModel.exchangeRateText
    if self.viewModel.isFocusingFromAmount {
      self.toAmountTextField.text = self.viewModel.expectedReceivedAmountText
      self.viewModel.updateAmount(self.toAmountTextField.text ?? "", isSource: false)
    } else {
      self.fromAmountTextField.text = self.viewModel.expectedExchangeAmountText
      self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    }
    self.view.layoutIfNeeded()
  }

  /*
   Update estimate gas limit, check if the from, to, amount are all the same as current value in the model    Update UIs according to new values
   */
  func coordinatorDidUpdateEstimateGasUsed(from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    self.viewModel.updateEstimateGasLimit(
      for: from,
      to: to,
      amount: amount,
      gasLimit: gasLimit
    )
  }

  /*
   Update selected token
   - token: New selected token
   - isSource: true if selected token is from, otherwise it is to
   Update UIs according to new values
   */
  func coordinatorUpdateSelectedToken(_ token: TokenObject, isSource: Bool) {
    if isSource, self.viewModel.from == token { return }
    if !isSource, self.viewModel.to == token { return }
    self.viewModel.updateSelectedToken(token, isSource: isSource)

    if self.viewModel.isFocusingFromAmount {
      self.fromAmountTextField.text = self.viewModel.amountFrom
      self.toAmountTextField.text = self.viewModel.expectedReceivedAmountText
    } else {
      self.toAmountTextField.text = self.viewModel.amountTo
      self.fromAmountTextField.text = self.viewModel.expectedExchangeAmountText
    }
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    self.viewModel.updateAmount(self.toAmountTextField.text ?? "", isSource: false)
    self.updateTokensView(updatedFrom: isSource, updatedTo: !isSource)
  }

  /*
    Result from sending exchange token
   */
  func coordinatorExchangeTokenDidReturn(result: Result<String, AnyError>) {
    if case .failure(let error) = result {
      self.displayError(error: error)
    }
  }

  /*
    Show transaction status after user confirmed transaction
   */
  func coordinatorExchangeTokenUserDidConfirmTransaction() {
    // Reset exchange amount
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.viewModel.updateFocusingField(true)
    self.toAmountTextField.text = ""
    self.fromAmountTextField.text = ""
  }

  /*
    - gasPrice: new gas price after user finished selected gas price from set gas price view
   */
  func coordinatorExchangeTokenDidUpdateGasPrice(_ gasPrice: BigInt?) {
    if let gasPrice = gasPrice {
      self.viewModel.updateGasPrice(gasPrice)
    }
    self.gasPriceSegmentedControl.selectedSegmentIndex = self.viewModel.selectedGasPriceType.rawValue
    self.view.layoutIfNeeded()
  }

  func coordinatorDidUpdatePendingTransactions(_ transactions: [Transaction]) {
    self.hamburgerMenu.update(transactions: transactions)
    self.walletHeaderView.updateBadgeCounter(transactions.count)
  }
}

// MARK: UITextFieldDelegate
extension KNExchangeTabViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.viewModel.updateAmount("", isSource: textField == self.fromAmountTextField)
    self.updateViewAmountDidChange()
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    if textField == self.fromAmountTextField && text.fullBigInt(decimals: self.viewModel.from.decimals) == nil { return false }
    if textField == self.toAmountTextField && text.fullBigInt(decimals: self.viewModel.to.decimals) == nil { return false }
    if text.isEmpty || Double(text) != nil {
      textField.text = text
      self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
      self.viewModel.updateAmount(text, isSource: textField == self.fromAmountTextField)
      self.updateViewAmountDidChange()
    }
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.fromAmountTextField.textColor = UIColor(hex: "31CB9E")
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.fromAmountTextField.textColor = self.viewModel.amountTextFieldColor
  }

  fileprivate func updateViewAmountDidChange() {
    if self.viewModel.isFocusingFromAmount {
      self.toAmountTextField.text = self.viewModel.expectedReceivedAmountText
      self.viewModel.updateAmount(self.toAmountTextField.text ?? "", isSource: false)
    } else {
      self.fromAmountTextField.text = self.viewModel.expectedExchangeAmountText
      self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    }
    self.updateEstimatedRate()
    self.updateEstimatedGasLimit()
    if !self.fromAmountTextField.isFirstResponder {
      self.fromAmountTextField.textColor = self.viewModel.amountTextFieldColor
    }
  }
}

// MARK: Wallet Header View Delegate
extension KNExchangeTabViewController: KNWalletHeaderViewDelegate {
  func walletHeaderDebugButtonPressed(sender: KNWalletHeaderView) {
    let debugVC = KNDebugMenuViewController()
    self.present(debugVC, animated: true, completion: nil)
  }

  func walletHeaderScanQRCodePressed(wallet: KNWalletObject, sender: KNWalletHeaderView) {
    self.delegate?.exchangeTabViewController(self, run: .showQRCode)
  }

  func walletHeaderWalletListPressed(wallet: KNWalletObject, sender: KNWalletHeaderView) {
    self.hamburgerMenu.openMenu(animated: true)
  }
}

// MARK: Hamburger Menu Delegate
extension KNExchangeTabViewController: KNBalanceTabHamburgerMenuViewControllerDelegate {
  func balanceTabHamburgerMenuViewController(_ controller: KNBalanceTabHamburgerMenuViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    self.delegate?.exchangeTabViewController(self, run: event)
  }
}

// MARK: Toolbar delegate
extension KNExchangeTabViewController: KNCustomToolbarDelegate {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardExchangeAllButtonPressed(toolbar)
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}
