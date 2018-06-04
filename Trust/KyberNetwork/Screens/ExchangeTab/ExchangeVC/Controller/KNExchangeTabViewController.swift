// Copyright SIX DAY LLC. All rights reserved.
import UIKit
import BigInt
import Result

protocol KNExchangeTabViewControllerDelegate: class {
  func exchangeTabViewControllerFromTokenPressed(sender: KNExchangeTabViewController, from: TokenObject, to: TokenObject)
  func exchangeTabViewControllerToTokenPressed(sender: KNExchangeTabViewController, from: TokenObject, to: TokenObject)
  func exchangeTabViewControllerExchangeButtonPressed(sender: KNExchangeTabViewController, data: KNDraftExchangeTransaction)
  func exchangeTabViewControllerShouldUpdateEstimatedRate(from: TokenObject, to: TokenObject, amount: BigInt)
  func exchangeTabViewControllerShouldUpdateEstimatedGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, gasPrice: BigInt)
  func exchangeTabViewControllerDidPressedQRcode(sender: KNExchangeTabViewController)
  func exchangeTabViewControllerDidPressedGasPrice(gasPrice: BigInt, estGasLimit: BigInt)
  func exchangeTabViewControllerDidPressedSlippageRate(slippageRate: Double)
  func exchangeTabViewControllerDidPressedWallet(_ wallet: KNWalletObject, sender: KNExchangeTabViewController)
  func exchangeTabViewControllerDidPressedSendToken(sender: KNExchangeTabViewController)
  func exchangeTabViewControllerDidPressedAddWallet(sender: KNExchangeTabViewController)
  func exchangeTabViewControllerDidPressedSettings(sender: KNExchangeTabViewController)
}

class KNExchangeTabViewController: KNBaseViewController {

  @IBOutlet weak var walletHeaderView: KNWalletHeaderView!

  @IBOutlet weak var fromTokenButton: UIButton!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var toTokenButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!

  @IBOutlet weak var exchangeRateLabel: UILabel!

  @IBOutlet weak var equalButton: UIButton!
  @IBOutlet weak var amountContainerView: UIView!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var amountReceivedLabel: UILabel!

  @IBOutlet weak var gasPriceDetailsView: KNDataDetailsView!
  @IBOutlet weak var slippageRateDetailsView: KNDataDetailsView!
  @IBOutlet weak var exchangeButton: UIButton!

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

  lazy var toolBar: UIToolbar = {
    let toolBar = UIToolbar()
    toolBar.barStyle = .default
    toolBar.isTranslucent = true
    toolBar.barTintColor = UIColor(hex: "31cb9e")
    toolBar.tintColor = .white
    let exchangeAllBtn = UIBarButtonItem(
      title: "Exchange All",
      style: .plain,
      target: self,
      action: #selector(self.keyboardExchangeAllButtonPressed(_:))
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

  init(viewModel: KNExchangeTabViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNExchangeTabViewController.className, bundle: nil)
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
    self.setupExchangeDataView()
    self.setupHamburgerMenu()
  }

  fileprivate func setupWalletHeaderView() {
    self.walletHeaderView.delegate = self
    self.walletHeaderView.updateView(with: self.viewModel.walletObject)
  }

  fileprivate func setupTokensView() {
    self.fromTokenButton.rounded(radius: 4.0)
    self.fromTokenButton.addShadow()
    self.swapButton.rounded(radius: self.swapButton.frame.height / 2.0)
    self.toTokenButton.rounded(radius: 4.0)
    self.toTokenButton.addShadow()

    self.exchangeRateLabel.rounded(radius: 4.0)
    self.exchangeRateLabel.addShadow()

    self.amountContainerView.rounded(
      color: UIColor.black.withAlphaComponent(0.5),
      radius: 4.0
    )
    self.amountContainerView.addShadow()
    self.amountTextField.rounded(color: .lightGray, width: 1.0, radius: 4.0)
    self.amountTextField.delegate = self
    self.amountTextField.inputAccessoryView = self.toolBar
    self.equalButton.rounded(radius: self.equalButton.frame.height / 2.0)
    self.amountReceivedLabel.rounded(radius: 4.0)
    self.amountReceivedLabel.addShadow()

    self.updateTokensView()
  }

  fileprivate func setupExchangeDataView() {

    // setup gas price details view
    self.gasPriceDetailsView.rounded(
      color: UIColor(hex: "f1f1f1"),
      width: 1,
      radius: 0
    )
    let tapGasPriceGesture = UITapGestureRecognizer(target: self, action: #selector(self.gasPriceDataDetailsViewTapped(_:)))
    self.gasPriceDetailsView.addGestureRecognizer(tapGasPriceGesture)

    // setup slippage rate details view
    self.slippageRateDetailsView.rounded(
      color: UIColor(hex: "f1f1f1"),
      width: 1,
      radius: 0
    )
    let tapSlippageRateGesture = UITapGestureRecognizer(target: self, action: #selector(self.slippageRateDataDetailsViewTapped(_:)))
    self.slippageRateDetailsView.addGestureRecognizer(tapSlippageRateGesture)
    self.exchangeButton.rounded(radius: 6.0)
    self.updateExchangeData()
  }

  fileprivate func setupHamburgerMenu() {
    self.hamburgerMenu.hideMenu(animated: false)
  }

  @IBAction func fromTokenButtonPressed(_ sender: UIButton) {
    self.delegate?.exchangeTabViewControllerFromTokenPressed(
      sender: self,
      from: self.viewModel.from,
      to: self.viewModel.to
    )
  }

  @IBAction func toTokenButtonPressed(_ sender: UIButton) {
    self.delegate?.exchangeTabViewControllerToTokenPressed(
      sender: self,
      from: self.viewModel.from,
      to: self.viewModel.to
    )
  }

  @IBAction func swapButtonPressed(_ sender: UIButton) {
    self.viewModel.swapTokens()
    UIView.animate(
      withDuration: 0.3,
      delay: 0,
      options: .transitionFlipFromTop,
      animations: {
      self.amountTextField.text = ""
      self.updateTokensView()
    }, completion: nil
    )
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
    guard self.viewModel.isAmountValid else {
      self.showWarningTopBannerMessage(with: "Invalid amount", message: "Please enter a valid amount to exchange")
      return
    }
    guard self.viewModel.isRateValid else {
      self.showWarningTopBannerMessage(with: "Invalid rate", message: "Please wait for estimated rate to exchange")
      return
    }
    // TODO: This is not true in case we could exchange token/token
    guard self.viewModel.from != self.viewModel.to, self.viewModel.from.isETH || self.viewModel.to.isETH else {
      self.showWarningTopBannerMessage(with: "Invalid tokens", message: "Only can exchange between ETH and other tokens")
      return
    }
    let slippageRate: BigInt? = {
      guard let percent = self.viewModel.slippagePercentage, let estRate = self.viewModel.estRate else {
        return self.viewModel.slippageRate
      }
      return estRate * BigInt(100.0 - percent) / BigInt(100)
    }()
    let exchange = KNDraftExchangeTransaction(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: self.viewModel.amountBigInt,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: self.viewModel.estRate ?? BigInt(0),
      minRate: slippageRate,
      gasPrice: self.viewModel.gasPrice,
      gasLimit: self.viewModel.estimateGasLimit
    )
    self.delegate?.exchangeTabViewControllerExchangeButtonPressed(
      sender: self,
      data: exchange
    )
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    self.hamburgerMenu.gestureScreenEdgePanAction(sender)
  }

  @objc func gasPriceDataDetailsViewTapped(_ sender: Any) {
    self.delegate?.exchangeTabViewControllerDidPressedGasPrice(
      gasPrice: self.viewModel.gasPrice,
      estGasLimit: self.viewModel.estimateGasLimit
    )
  }

  @objc func slippageRateDataDetailsViewTapped(_ sender: Any) {
    let slippagePercent: Double? = {
      if self.viewModel.slippagePercentage != nil { return self.viewModel.slippagePercentage }
      if let rate = self.viewModel.estRate, let slippageRate = self.viewModel.slippageRate, !rate.isZero {
        let percent = (rate - slippageRate) * BigInt(100) / rate
        return Double(percent.shortString(decimals: 0))
      }
      return nil
    }()
    if let percent = slippagePercent {
      self.delegate?.exchangeTabViewControllerDidPressedSlippageRate(
        slippageRate: percent)
    }
  }

  @objc func keyboardExchangeAllButtonPressed(_ sender: Any) {
    self.amountTextField.text = self.viewModel.balance?.amountFull ?? ""
    self.amountTextField.resignFirstResponder()
    self.viewModel.updateAmount(self.amountTextField.text ?? "")
    self.updateTokensView()
    self.updateViewAmountDidChange()
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.amountTextField.resignFirstResponder()
  }

  fileprivate func updateEstimatedRate() {
    self.delegate?.exchangeTabViewControllerShouldUpdateEstimatedRate(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: self.viewModel.amountBigInt
    )
  }

  fileprivate func updateEstimatedGasLimit() {
    self.delegate?.exchangeTabViewControllerShouldUpdateEstimatedGasLimit(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: self.viewModel.amountBigInt,
      gasPrice: self.viewModel.gasPrice
    )
  }
}

// MARK: Update UIs
extension KNExchangeTabViewController {
  /*
    Update tokens view when either from or to tokens changed
      - updatedFrom: true if from token is changed
      - updatedTo: true if to token is changed
   */
  // TODO: Remove default token icon image
  func updateTokensView(updatedFrom: Bool = true, updatedTo: Bool = true) {
    if updatedFrom {
      self.fromTokenButton.setTitle(self.viewModel.fromTokenBtnTitle, for: .normal)
      self.fromTokenButton.setImage(UIImage(named: self.viewModel.fromTokenIconName) ?? self.viewModel.defaultTokenIconImg, for: .normal)
    }
    if updatedTo {
      self.toTokenButton.setTitle(self.viewModel.toTokenBtnTitle, for: .normal)
      self.toTokenButton.setImage(UIImage(named: self.viewModel.toTokenIconName) ?? self.viewModel.defaultTokenIconImg, for: .normal)
    }
    self.balanceLabel.text = self.viewModel.balanceText
    // Temporary update rate using CMC data
    if let cmcRate = KNRateCoordinator.shared.getRate(from: self.viewModel.from, to: self.viewModel.to) {
      self.viewModel.updateExchangeRate(
        for: self.viewModel.from,
        to: self.viewModel.to,
        amount: self.viewModel.amountBigInt,
        rate: cmcRate.rate,
        slippageRate: cmcRate.minRate
      )
    }
    self.exchangeRateLabel.text = self.viewModel.exchangeRateText
    self.amountReceivedLabel.text = self.viewModel.expectedReceivedAmountText
    self.view.layoutIfNeeded()
  }

  func updateExchangeData() {
    self.gasPriceDetailsView.updateView(
      with: "Gas Price",
      subTitle: self.viewModel.gasPriceText
    )
    self.slippageRateDetailsView.updateView(
      with: "Slippage Rate",
      subTitle: self.viewModel.slippageRateText
    )
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
    self.amountTextField.text = ""
    self.updateTokensView()
    self.updateExchangeData()
    self.updateViewAmountDidChange()
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.balanceLabel.text = self.viewModel.balanceText
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
    self.amountReceivedLabel.text = self.viewModel.expectedReceivedAmountText
    self.slippageRateDetailsView.updateView(
      with: "Slippage Rate",
      subTitle: self.viewModel.slippageRateText
    )
    self.view.layoutIfNeeded()
  }

  /*
   Update estimate gas limit, check if the from, to, amount are all the same as current value in the model
   Update UIs according to new values
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
    UIView.animate(
      withDuration: 0.3,
      delay: 0,
      options: .transitionFlipFromTop,
      animations: {
      if !isSource {
        self.amountTextField.text = ""
        self.updateViewAmountDidChange()
      }
      self.updateTokensView(updatedFrom: isSource, updatedTo: !isSource)
    }, completion: nil
    )
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
    self.amountTextField.text = ""
    self.viewModel.updateAmount("")
    self.updateViewAmountDidChange()
  }

  /*
    - gasPrice: new gas price after user finished selected gas price from set gas price view
   */
  func coordinatorExchangeTokenDidUpdateGasPrice(_ gasPrice: BigInt) {
    self.viewModel.updateGasPrice(gasPrice)
    self.gasPriceDetailsView.updateView(
      with: "Gas Price",
      subTitle: self.viewModel.gasPriceText)
    self.view.layoutIfNeeded()
  }

  /*
   - percent: new slippage rate after user finished selected slippage rate from set slippage rate
   */
  func coordinatorExchangeTokenDidUpdateSlippageRate(_ percent: Double) {
    self.viewModel.updateSlippagePercent(percent)
    self.slippageRateDetailsView.updateView(
      with: "Slippage Rate",
      subTitle: self.viewModel.slippageRateText
    )
  }
}

// MARK: UITextFieldDelegate
extension KNExchangeTabViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateAmount("")
    self.updateViewAmountDidChange()
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    if text.isEmpty || Double(text) != nil {
      textField.text = text
      self.viewModel.updateAmount(text)
      self.updateViewAmountDidChange()
    }
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    textField.layer.borderColor = UIColor(hex: "31cb9e").cgColor
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    textField.layer.borderColor = UIColor.lightGray.cgColor
  }

  fileprivate func updateViewAmountDidChange() {
    self.amountReceivedLabel.text = self.viewModel.expectedReceivedAmountText
    self.updateEstimatedRate()
    self.updateEstimatedGasLimit()
  }
}

// MARK: Wallet Header View Delegate
extension KNExchangeTabViewController: KNWalletHeaderViewDelegate {
  func walletHeaderDebugButtonPressed(sender: KNWalletHeaderView) {
    let debugVC = KNDebugMenuViewController()
    self.present(debugVC, animated: true, completion: nil)
  }

  func walletHeaderScanQRCodePressed(wallet: KNWalletObject, sender: KNWalletHeaderView) {
    self.delegate?.exchangeTabViewControllerDidPressedQRcode(sender: self)
  }

  func walletHeaderWalletListPressed(wallet: KNWalletObject, sender: KNWalletHeaderView) {
    self.hamburgerMenu.openMenu(animated: true)
  }
}

// MARK: Hamburger Menu Delegate
extension KNExchangeTabViewController: KNBalanceTabHamburgerMenuViewControllerDelegate {
  func balanceTabHamburgerMenuDidSelectAddWallet(sender: KNBalanceTabHamburgerMenuViewController) {
    self.delegate?.exchangeTabViewControllerDidPressedAddWallet(sender: self)
  }

  func balanceTabHamburgerMenuDidSelectSettings(sender: KNBalanceTabHamburgerMenuViewController) {
    self.delegate?.exchangeTabViewControllerDidPressedSettings(sender: self)
  }

  func balanceTabHamburgerMenuDidSelectSendToken(sender: KNBalanceTabHamburgerMenuViewController) {
    self.delegate?.exchangeTabViewControllerDidPressedSendToken(sender: self)
  }

  func balanceTabHamburgerMenuDidSelect(wallet: KNWalletObject, sender: KNBalanceTabHamburgerMenuViewController) {
    self.delegate?.exchangeTabViewControllerDidPressedWallet(wallet, sender: self)
  }
}
