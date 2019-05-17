// Copyright SIX DAY LLC. All rights reserved.

//swiftlint:disable file_length
import UIKit
import BigInt

enum KNCreateLimitOrderViewEvent {
  case searchToken(from: TokenObject, to: TokenObject, isSource: Bool)
  case estimateRate(from: TokenObject, to: TokenObject, amount: BigInt, showWarning: Bool)
  case suggestBuyToken
  case submitOrder(order: KNLimitOrder)
  case manageOrders
}

protocol KNCreateLimitOrderViewControllerDelegate: class {
  func kCreateLimitOrderViewController(_ controller: KNCreateLimitOrderViewController, run event: KNCreateLimitOrderViewEvent)
  func kCreateLimitOrderViewController(_ controller: KNCreateLimitOrderViewController, run event: KNBalanceTabHamburgerMenuViewEvent)
}

class KNCreateLimitOrderViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var limitOrderTextLabel: UILabel!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var hasPendingTxView: UIView!

  @IBOutlet weak var tokenDateContainerView: UIView!
  @IBOutlet weak var fromTokenButton: UIButton!
  @IBOutlet weak var fromAmountTextField: UITextField!
  @IBOutlet weak var toTokenButton: UIButton!
  @IBOutlet weak var toAmountTextField: UITextField!

  @IBOutlet weak var sourceBalanceTextLabel: UILabel!
  @IBOutlet weak var sourceBalanceValueLabel: UILabel!

  @IBOutlet var percentageButtons: [UIButton]!

  @IBOutlet weak var rateContainerView: UIView!

  @IBOutlet weak var rateOfTextLabel: UILabel!
  @IBOutlet weak var pairTokensLabel: UILabel!
  @IBOutlet weak var targetRateTextField: UITextField!

  @IBOutlet weak var currentRateLabel: UILabel!
  @IBOutlet weak var compareMarketRateLabel: UILabel!

  @IBOutlet weak var separatorView: UIView!

  @IBOutlet weak var feeNoteLabel: UILabel!
  @IBOutlet weak var suggestBuyTokenButton: UIButton!

  @IBOutlet weak var submitOrderButton: UIButton!

  @IBOutlet weak var relatedOrdersContainerView: UIView!
  @IBOutlet weak var relatedOrderContainerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var relatedOrderTextLabel: UILabel!
  @IBOutlet weak var relatedManageOrderButton: UIButton!

  @IBOutlet weak var manageOrdersButton: UIButton!

  fileprivate var isViewSetup: Bool = false
  fileprivate var isErrorMessageEnabled: Bool = false
  fileprivate var viewModel: KNCreateLimitOrderViewModel
  weak var delegate: KNCreateLimitOrderViewControllerDelegate?

  @IBOutlet var submitButtonBottomPaddingToRelatedOrderViewConstraint: NSLayoutConstraint!
  @IBOutlet var submitButtonBottomPaddingToContainerViewConstraint: NSLayoutConstraint!
  @IBOutlet weak var scrollViewBottomPaddingConstraints: NSLayoutConstraint!

  @IBOutlet weak var relatedOrderCollectionView: UICollectionView!

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
      leftBtnTitle: "All Balance".toBeLocalised(),
      rightBtnTitle: NSLocalizedString("done", value: "Done", comment: ""),
      barTintColor: UIColor.Kyber.enygold,
      delegate: self)
  }()

  init(viewModel: KNCreateLimitOrderViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNCreateLimitOrderViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.submitOrderButton.applyGradient()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.isErrorMessageEnabled = true
    self.updateEstimateRate(showWarning: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.border)
    self.submitOrderButton.removeSublayer(at: 0)
    self.submitOrderButton.applyGradient()

    self.tokenDateContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 7),
      opacity: 0.32,
      radius: 32
    )
    self.rateContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 4),
      opacity: 0.16,
      radius: 16
    )
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isErrorMessageEnabled = false
    self.view.endEditing(true)
  }

  fileprivate func setupUI() {
    self.walletNameLabel.text = self.viewModel.walletNameString

    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.border)
    self.separatorView.backgroundColor = .clear
    self.submitOrderButton.rounded(radius: self.submitOrderButton.frame.height / 2.0)

    self.tokenDateContainerView.rounded(radius: 4.0)
    self.fromAmountTextField.text = ""
    self.fromAmountTextField.adjustsFontSizeToFitWidth = true
    self.fromAmountTextField.inputAccessoryView = self.toolBar
    self.fromAmountTextField.delegate = self

    self.toAmountTextField.text = ""
    self.toAmountTextField.adjustsFontSizeToFitWidth = true
    self.toAmountTextField.inputAccessoryView = self.toolBar
    self.toAmountTextField.delegate = self

    self.rateContainerView.rounded(radius: 4.0)
    self.targetRateTextField.text = ""
    self.targetRateTextField.adjustsFontSizeToFitWidth = true
    self.targetRateTextField.delegate = self

    self.percentageButtons.forEach({ $0.rounded(radius: 2.5) })

    self.relatedOrderTextLabel.text = "Related Orders".toBeLocalised().uppercased()
    self.relatedManageOrderButton.setTitle("Manage Orders".toBeLocalised(), for: .normal)
    self.manageOrdersButton.setTitle("Manage Orders".toBeLocalised(), for: .normal)

    self.updateTokensView(updatedFrom: true, updatedTo: true)

    self.scrollViewBottomPaddingConstraints.constant = self.bottomPaddingSafeArea()

    let orderCellNib = UINib(nibName: KNLimitOrderCollectionViewCell.className, bundle: nil)
    self.relatedOrderCollectionView.register(
      orderCellNib,
      forCellWithReuseIdentifier: KNLimitOrderCollectionViewCell.cellID
    )
    self.relatedOrderCollectionView.delegate = self
    self.relatedOrderCollectionView.dataSource = self
    self.updateRelatedOrdersView()

    if let rate = self.viewModel.rateFromNode ?? self.viewModel.cachedProdRate, !rate.isZero {
      let rateString = rate.displayRate(decimals: self.viewModel.to.decimals)
      self.targetRateTextField.text = rateString
      self.viewModel.updateTargetRate(rateString)
    }
    // Update hamburger menu
    self.hasPendingTxView.rounded(radius: self.hasPendingTxView.frame.height / 2.0)
    self.hamburgerMenu.hideMenu(animated: false)
  }

  @IBAction func fromTokenButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "limit_order", customAttributes: ["type": "from_token_pressed"])
    self.delegate?.kCreateLimitOrderViewController(self, run: .searchToken(from: self.viewModel.from, to: self.viewModel.to, isSource: true))
  }

  @IBAction func toTokenButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "limit_order", customAttributes: ["type": "to_token_pressed"])
    self.delegate?.kCreateLimitOrderViewController(self, run: .searchToken(from: self.viewModel.from, to: self.viewModel.to, isSource: false))
  }

  @IBAction func swapTokensButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "limit_order", customAttributes: ["type": "swap_2_tokens"])
    if self.viewModel.to.isETH {
      self.showWarningTopBannerMessage(
        with: "Unsupported".toBeLocalised(),
        message: "We don't support limit order with ETH as source token, but you can use WETH instead".toBeLocalised(),
        time: 2.0
      )
      return
    }
    self.viewModel.swapTokens()
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.targetRateTextField.text = ""
    self.updateTokensView()
    self.updateEstimateRate(showWarning: true)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    self.hamburgerMenu.gestureScreenEdgePanAction(sender)
  }

  @IBAction func hamburgerMenuButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "limit_order", customAttributes: ["type": "hamburger_menu"])
    self.view.endEditing(true)
    self.hamburgerMenu.openMenu(animated: true)
  }

  @IBAction func firstPercentageButtonPressed(_ sender: Any) {
    let amountDisplay = self.viewModel.amountFromWithPercentage(25).displayRate(decimals: self.viewModel.from.decimals).removeGroupSeparator()
    self.viewModel.updateAmount(amountDisplay, isSource: true)
    self.fromAmountTextField.text = amountDisplay
    self.viewModel.updateFocusTextField(0)
    self.updateViewAmountDidChange()
    _ = self.validateDataIfNeeded()
  }

  @IBAction func secondPercentageButtonPressed(_ sender: Any) {
    let amountDisplay = self.viewModel.amountFromWithPercentage(50).displayRate(decimals: self.viewModel.from.decimals).removeGroupSeparator()
    self.viewModel.updateAmount(amountDisplay, isSource: true)
    self.fromAmountTextField.text = amountDisplay
    self.viewModel.updateFocusTextField(0)
    self.updateViewAmountDidChange()
    _ = self.validateDataIfNeeded()
  }

  @IBAction func thirdPercentageButtonPressed(_ sender: Any) {
    let amountDisplay = self.viewModel.amountFromWithPercentage(100).displayRate(decimals: self.viewModel.from.decimals).removeGroupSeparator()
    self.viewModel.updateAmount(amountDisplay, isSource: true)
    self.fromAmountTextField.text = amountDisplay
    self.viewModel.updateFocusTextField(0)
    self.updateViewAmountDidChange()
    _ = self.validateDataIfNeeded()
  }

  @IBAction func suggestBuyTokenButtonPressed(_ sender: Any) {
    self.delegate?.kCreateLimitOrderViewController(self, run: .suggestBuyToken)
  }

  @IBAction func submitOrderButtonPressed(_ sender: Any) {
    if !self.validateDataIfNeeded(isConfirming: true) { return }
    if case .real(let account) = self.viewModel.wallet.type {
      let order = KNLimitOrder(
        from: self.viewModel.from,
        to: self.viewModel.to,
        account: account,
        sender: self.viewModel.wallet.address,
        srcAmount: self.viewModel.amountFromBigInt,
        targetRate: self.viewModel.targetRateBigInt,
        fee: self.viewModel.feeBigInt,
        nonce: 0
      )
      self.delegate?.kCreateLimitOrderViewController(self, run: .submitOrder(order: order))
    }
  }

  @IBAction func manageOrderButtonPressed(_ sender: Any) {
    self.delegate?.kCreateLimitOrderViewController(self, run: .manageOrders)
  }

  @objc func keyboardSwapAllButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "limit_order", customAttributes: ["type": "swap_all"])
    self.view.endEditing(true)
    self.fromAmountTextField.text = self.viewModel.allFromTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    self.updateTokensView()
    self.updateViewAmountDidChange()
    self.view.layoutIfNeeded()
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.view.layoutIfNeeded()
  }

  @objc func balanceLabelTapped(_ sender: Any) {
    self.keyboardSwapAllButtonPressed(sender)
  }
}

// MARK: Update UIs
extension KNCreateLimitOrderViewController {
  // Update related order view, hide or show related orders
  fileprivate func updateRelatedOrdersView() {
    // TODO: Remove
    let orders = self.viewModel.relatedOrders.filter({
      return $0.sourceToken == self.viewModel.from.symbol
        && $0.destToken == self.viewModel.to.symbol
        && $0.sender.lowercased() == self.viewModel.walletObject.address.lowercased()
    })
    self.viewModel.updateRelatedOrders(orders)

    let numberOrders = self.viewModel.relatedOrders.count
    if numberOrders > 0 {
      self.submitButtonBottomPaddingToContainerViewConstraint.isActive = false
      self.submitButtonBottomPaddingToRelatedOrderViewConstraint.isActive = true
      self.submitButtonBottomPaddingToRelatedOrderViewConstraint.constant = 32.0
      let orderCellHeight = KNLimitOrderCollectionViewCell.height + 12.0 // height + bottom padding
      self.relatedOrderContainerViewHeightConstraint.constant = 32.0 + CGFloat(numberOrders) * orderCellHeight // top padding + collection view height
      self.relatedOrdersContainerView.isHidden = false
      self.manageOrdersButton.isHidden = true
      self.relatedOrderCollectionView.reloadData()
    } else {
      self.submitButtonBottomPaddingToContainerViewConstraint.isActive = true
      self.submitButtonBottomPaddingToContainerViewConstraint.constant = 88.0
      self.submitButtonBottomPaddingToRelatedOrderViewConstraint.isActive = false
      self.relatedOrdersContainerView.isHidden = true
      self.manageOrdersButton.isHidden = false
    }
  }

  // Update current martket rate with rate from node or cached
  fileprivate func updateCurrentMarketRateUI() {
    self.currentRateLabel.text = String(format: "Current Rate: %@", self.viewModel.exchangeRateText)
    self.compareMarketRateLabel.attributedText = self.viewModel.displayRateCompareAttributedString
  }

  // Update fee when source amount changed
  fileprivate func updateFeeNotesUI() {
    self.feeNoteLabel.text = self.viewModel.displayFeeString
    self.suggestBuyTokenButton.setTitle(self.viewModel.suggestBuyText, for: .normal)
  }

  // Call update estimate rate from node
  fileprivate func updateEstimateRate(showWarning: Bool = false) {
    let event = KNCreateLimitOrderViewEvent.estimateRate(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: self.viewModel.amountFromBigInt,
      showWarning: showWarning
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

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
      self.sourceBalanceTextLabel.text = self.viewModel.balanceTextString
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
    self.sourceBalanceValueLabel.text = self.viewModel.balanceText
    self.pairTokensLabel.text = "\(self.viewModel.from.symbol) ➞ \(self.viewModel.to.symbol)"

    self.updateCurrentMarketRateUI()
    self.updateFeeNotesUI()

    self.updateViewAmountDidChange()
    self.updateRelatedOrdersView()

    self.view.layoutIfNeeded()
  }
}

// MARK: Data validation
extension KNCreateLimitOrderViewController {
  fileprivate func validateDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming && !self.isErrorMessageEnabled || !self.hamburgerMenu.view.isHidden { return false }
    if !isConfirming && (self.fromAmountTextField.isEditing || self.toAmountTextField.isEditing) { return false }
    guard self.viewModel.from != self.viewModel.to else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: "Can not create an order with same token".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    guard self.viewModel.isBalanceEnough else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
        message: NSLocalizedString("balance.not.enough.to.make.transaction", value: "Balance is not enough to make the transaction.", comment: "")
      )
      return false
    }
    guard !self.viewModel.isAmountTooBig else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: "Amount too big, your amount should be between 0.5 ETH to 10 ETH in equivalent".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    guard !self.viewModel.isAmountTooSmall else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: "Amount too small, your amount should be between 0.5 ETH to 10 ETH in equivalent".toBeLocalised(),
        time: 1.5
      )
      return false
    }
//    if isConfirming {
//      if self.viewModel.percentageRateDiff <= 0 {
//        self.showWarningTopBannerMessage(
//          with: "Warning".toBeLocalised(),
//          message: "Your target rate is lower than current market rate".toBeLocalised(),
//          time: 1.5
//        )
//      }
//    }
    return true
  }
}

// MARK: Update from coordinator
extension KNCreateLimitOrderViewController {
  /*
   Update new session when current wallet is changed, update all UIs
   */
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.updateWallet(wallet)
    self.walletNameLabel.text = self.viewModel.walletNameString
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.targetRateTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.viewModel.updateTargetRate("")
    self.updateTokensView()
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
    self.hamburgerMenu.hideMenu(animated: false)
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateWalletObjects() {
    self.viewModel.updateWalletObject()
    self.walletNameLabel.text = self.viewModel.walletNameString
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.sourceBalanceValueLabel.text = self.viewModel.balanceText
    self.view.layoutIfNeeded()
  }

  /*
   Update estimate rate, check if the from, to, amount are all the same as current value in the model
   Update UIs according to new values
   */
  func coordinatorDidUpdateEstimateRate(from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) {
    let updated = self.viewModel.updateExchangeRate(
      for: from,
      to: to,
      amount: amount,
      rate: rate,
      slippageRate: slippageRate
    )
    if updated { self.updateCurrentMarketRateUI() }
    self.view.layoutIfNeeded()
  }

  /*
   Update selected token
   - token: New selected token
   - isSource: true if selected token is from, otherwise it is to
   Update UIs according to new values
   */
  func coordinatorUpdateSelectedToken(_ token: TokenObject, isSource: Bool, isWarningShown: Bool = true) {
    if isSource, !self.fromTokenButton.isEnabled { return }
    if !isSource, !self.toTokenButton.isEnabled { return }
    if isSource, self.viewModel.from == token { return }
    if !isSource, self.viewModel.to == token { return }
    if isSource, token.isETH {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: "We don't support limit order with ETH as source token, but you can use WETH instead".toBeLocalised(),
        time: 2.0
      )
      return
    }
    self.viewModel.updateSelectedToken(token, isSource: isSource)
    if isSource && self.viewModel.focusTextFieldTag == 0 {
      self.viewModel.updateAmount("", isSource: isSource)
      self.fromAmountTextField.text = ""
    } else if !isSource && self.viewModel.focusTextFieldTag == 1 {
      self.viewModel.updateAmount("", isSource: isSource)
      self.toAmountTextField.text = ""
    }
    // support for promo wallet
    let isUpdatedTo: Bool = !isSource
    self.updateTokensView(updatedFrom: isSource, updatedTo: isUpdatedTo)
    if self.viewModel.from == self.viewModel.to && isWarningShown {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: "Can not create an order with same token".toBeLocalised(),
        time: 1.5
      )
    }
    // auto fill current rate
    if let rate = self.viewModel.rateFromNode ?? self.viewModel.cachedProdRate, !rate.isZero {
      let rateString = rate.displayRate(decimals: self.viewModel.to.decimals)
      self.targetRateTextField.text = rateString
      self.viewModel.updateTargetRate(rateString)
    }
    self.updateViewAmountDidChange()
    self.view.layoutIfNeeded()
  }

  /*
   Show transaction status after user confirmed transaction
   */
  func coordinatorExchangeTokenUserDidConfirmTransaction() {
    // Reset exchange amount
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.viewModel.updateTargetRate("")
    self.toAmountTextField.text = ""
    self.fromAmountTextField.text = ""
    self.targetRateTextField.text = ""
    self.updateCurrentMarketRateUI()
    self.view.layoutIfNeeded()
  }

  func coordinatorTrackerRateDidUpdate() {
    self.updateCurrentMarketRateUI()
  }

  func coordinatorUpdateProdCachedRates() {
    self.viewModel.updateProdCachedRate()
    self.updateCurrentMarketRateUI()
  }

  func coordinatorUpdateComparedRateFromNode(from: TokenObject, to: TokenObject, rate: BigInt) {
    if self.viewModel.from == from, self.viewModel.to == to {
      self.viewModel.updateProdCachedRate(rate)
      self.updateCurrentMarketRateUI()
    }
  }

  func coordinatorDidUpdatePendingTransactions(_ transactions: [KNTransaction]) {
    self.hamburgerMenu.update(transactions: transactions)
    self.hasPendingTxView.isHidden = transactions.isEmpty
    self.view.layoutIfNeeded()
  }

  // TODO: Remove
  func coordinatorDoneSubmittingOrder(_ order: KNLimitOrder) {
    var orders = self.viewModel.relatedOrders
    orders.append(KNOrderObject.getOrderObject(from: order))
    self.viewModel.updateRelatedOrders(orders)
    self.updateRelatedOrdersView()
  }
}

// MARK: UITextField delegation
extension KNCreateLimitOrderViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    self.viewModel.updateFocusTextField(textField.tag)
    textField.text = ""
    if textField == self.fromAmountTextField || textField == self.toAmountTextField {
      self.viewModel.updateAmount("", isSource: textField == self.fromAmountTextField)
    } else if textField == self.targetRateTextField {
      self.viewModel.updateTargetRate("")
    }
    self.updateViewAmountDidChange()
    self.updateEstimateRate(showWarning: true)
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()

    // from amount text field
    if textField == self.fromAmountTextField && text.fullBigInt(decimals: self.viewModel.from.decimals) == nil { return false }

    // to amount text field
    if (textField == self.toAmountTextField || textField == self.targetRateTextField ) && text.fullBigInt(decimals: self.viewModel.to.decimals) == nil { return false }

    // validate if amount is less than 1B
    let double: Double = {
      if textField == self.fromAmountTextField {
        let bigInt = Double(text.fullBigInt(decimals: self.viewModel.from.decimals) ?? BigInt(0))
        return Double(bigInt) / pow(10.0, Double(self.viewModel.from.decimals))
      }
      let bigInt = Double(text.fullBigInt(decimals: self.viewModel.to.decimals) ?? BigInt(0))
      return Double(bigInt) / pow(10.0, Double(self.viewModel.to.decimals))
    }()
    if double > 1e9 && (textField.text?.count ?? 0) < text.count { return false } // more than 1B tokens

    textField.text = text

    self.viewModel.updateFocusTextField(textField.tag)

    if textField == self.fromAmountTextField {
      self.viewModel.updateAmount(text, isSource: true)
    } else if textField == self.toAmountTextField {
      self.viewModel.updateAmount(text, isSource: false)
    } else if textField == self.targetRateTextField {
      self.viewModel.updateTargetRate(text)
    }

    self.updateViewAmountDidChange()
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.updateFocusTextField(textField.tag)
    self.updateViewAmountDidChange()
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.viewModel.updateFocusTextField(textField.tag)
    self.updateEstimateRate(showWarning: true)
    self.updateViewAmountDidChange()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      _ = self.validateDataIfNeeded()
    }
  }

  fileprivate func updateViewAmountDidChange() {
    if self.viewModel.focusTextFieldTag != 1 {
      // Focusing from text field
      let amountTo = self.viewModel.estimateAmountToBigInt
      let amountToString = amountTo.isZero ? "" : amountTo.displayRate(decimals: self.viewModel.to.decimals).removeGroupSeparator()
      self.toAmountTextField.text = amountToString
      self.viewModel.updateAmount(amountToString, isSource: false)
    } else {
      // Focusing to text field
      let targetRate = self.viewModel.estimateTargetRateBigInt
      let rateDisplay = targetRate.isZero ? "" : targetRate.displayRate(decimals: self.viewModel.to.decimals).removeGroupSeparator()
      self.targetRateTextField.text = rateDisplay
      self.viewModel.updateTargetRate(rateDisplay)
    }
    self.updateFeeNotesUI()
    self.updateEstimateRate(showWarning: false)
    self.view.layoutIfNeeded()
  }
}

// MARK: Hamburger Menu Delegate
extension KNCreateLimitOrderViewController: KNBalanceTabHamburgerMenuViewControllerDelegate {
  func balanceTabHamburgerMenuViewController(_ controller: KNBalanceTabHamburgerMenuViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }
}

// MARK: Toolbar delegate
extension KNCreateLimitOrderViewController: KNCustomToolbarDelegate {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardSwapAllButtonPressed(toolbar)
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}

// MARK: Related orders
extension KNCreateLimitOrderViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 12.0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets.zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNLimitOrderCollectionViewCell.height
    )
  }
}

extension KNCreateLimitOrderViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    let order = self.viewModel.relatedOrders[indexPath.row]
    if let cancelOrder = self.viewModel.cancelOrder, cancelOrder.id == order.id {
      self.viewModel.cancelOrder = nil
      collectionView.reloadItems(at: [indexPath])
    }
  }
}

extension KNCreateLimitOrderViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.relatedOrders.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KNLimitOrderCollectionViewCell.cellID,
      for: indexPath
    ) as! KNLimitOrderCollectionViewCell
    let order = self.viewModel.relatedOrders[indexPath.row]
    let isReset: Bool = {
      if let cancelBtnOrder = self.viewModel.cancelOrder {
        return cancelBtnOrder.id != order.id
      }
      return true
    }()
    cell.updateCell(with: order, isReset: isReset)
    cell.delegate = self
    return cell
  }
}

extension KNCreateLimitOrderViewController: KNLimitOrderCollectionViewCellDelegate {
  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, cancelPressed order: KNOrderObject) {
    guard let id = self.viewModel.relatedOrders.firstIndex(where: { $0.id == order.id }) else {
      return
    }
    let alertController = UIAlertController(
      title: "".toBeLocalised(),
      message: "Do you want to cancel this order?".toBeLocalised(),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "Yes".toBeLocalised(), style: .default, handler: { _ in
      self.viewModel.cancelOrder = nil
      let indexPath = IndexPath(row: id, section: 0)
      self.relatedOrderCollectionView.reloadItems(at: [indexPath])
      self.showErrorTopBannerMessage(with: "", message: "Your order has been cancalled", time: 1.5)
    }))
    alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
      self.viewModel.cancelOrder = nil
      let indexPath = IndexPath(row: id, section: 0)
      self.relatedOrderCollectionView.reloadItems(at: [indexPath])
    }))
    self.present(alertController, animated: true, completion: nil)
  }
}
