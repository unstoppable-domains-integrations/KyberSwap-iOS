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
      leftBtnTitle: "Contribute All",
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
    self.balanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
      self?.reloadDataFromNode()
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.balanceTimer?.invalidate()
    self.balanceTimer = nil
  }

  fileprivate func setupUI() {
    self.setupTokenView()
    self.setupGasPriceView()
    self.setupSelectWallet()
  }

  fileprivate func setupTokenView() {
    self.buyAmountTextField.text = ""
    self.buyAmountTextField.adjustsFontSizeToFitWidth = true
    self.buyAmountTextField.inputAccessoryView = self.toolBar
    self.buyAmountTextField.delegate = self

    self.receivedAmountTextField.text = ""
    self.receivedAmountTextField.adjustsFontSizeToFitWidth = true

    self.receivedAmountTextField.delegate = self

    self.fromTokenButton.setAttributedTitle(
      self.viewModel.tokenButtonAttributedText(isSource: true),
      for: .normal
    )
    self.fromTokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.toIEOButton.setAttributedTitle(
      self.viewModel.tokenButtonAttributedText(isSource: false),
      for: .normal
    )
    self.updateBalanceAndRate()
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

  fileprivate func updateBalanceAndRate() {
    self.balanceTextLabel.text = self.viewModel.balanceTextString
    self.tokenBalanceLabel.text = self.viewModel.balanceText
    if !self.buyAmountTextField.isFirstResponder {
      self.buyAmountTextField.textColor = self.viewModel.amountTextFieldColor
    }
    self.rateLabel.text = self.viewModel.exchangeRateText
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.ieoBuyTokenViewController(self, run: .close)
  }

  @IBAction func fromTokenButtonPressed(_ sender: Any) {
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
    guard let _ = IEOUserStorage.shared.user else { return }
    let wallets = KNWalletStorage.shared.wallets
    if wallets.isEmpty {
      self.showWarningTopBannerMessage(
        with: "",
        message: "You need to add at least one registered address with KyberGO to buy token.",
        time: 2.5
      )
      return
    }
    let wallet: KNWalletObject = {
      if let id = wallets.index(of: self.viewModel.walletObject) {
        return wallets[(id + 1) % wallets.count]
      }
      return wallets[0]
    }()
    if wallet == self.viewModel.walletObject {
      self.showWarningTopBannerMessage(
        with: "",
        message: "To user another address, you'll need to import it first",
        time: 2.5
      )
      return
    }
    self.viewModel.updateWallet(wallet)
    self.buyAmountTextField.text = ""
    self.receivedAmountTextField.text = ""
    self.selectWalletButton.setTitle(self.viewModel.walletButtonTitle, for: .normal)
    self.updateBalanceAndRate()
    self.reloadDataFromNode()
    self.updateViewAmountDidChange()
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
    if self.viewModel.isAmountTooSmall {
      self.showWarningTopBannerMessage(
        with: "Invalid Amount".toBeLocalised(),
        message: "Amount is too small to buy token sale, minimum contribute equivalent to 0.001 ETH".toBeLocalised()
      )
      return
    }
    if self.viewModel.isAmountTooBig {
      self.showWarningTopBannerMessage(
        with: "Invalid Amount".toBeLocalised(),
        message: "Amount is too big to buy token sale".toBeLocalised()
      )
      return
    }
    guard self.viewModel.isRateValid else {
      self.showWarningTopBannerMessage(
        with: "Invalid Rate".toBeLocalised(),
        message: "We could not update rate from node".toBeLocalised()
      )
      return
    }
    if IEOTransactionStorage.shared.objects.first(where: {
      $0.txStatus == .pending && $0.srcAddress.lowercased() == self.viewModel.walletObject.address.lowercased()
    }) != nil {
      // User has one pending IEO tx with same address
      self.showWarningTopBannerMessage(
        with: "",
        message: "You have another pending token sale transaction, it might be lost if you send another transaction",
        time: 2.5
      )
    }

    self.delegate?.ieoBuyTokenViewController(
      self,
      run: .buy(transaction: self.viewModel.transaction)
    )
  }

  @objc func keyboardAllButtonPressed(_ sender: Any) {
    self.buyAmountTextField.text = self.viewModel.allFromTokenBalanceString
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

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended { self.delegate?.ieoBuyTokenViewController(self, run: .close) }
  }

  fileprivate func reloadDataFromNode() {
    IEOProvider.shared.getBalance(
      for: self.viewModel.walletObject.address,
      token: self.viewModel.from) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let bal) = result {
        self.viewModel.updateBalance(bal)
        self.tokenBalanceLabel.text = self.viewModel.balanceText
        if !self.buyAmountTextField.isFirstResponder {
          self.buyAmountTextField.textColor = self.viewModel.amountTextFieldColor
        }
      }
    }
    if !self.viewModel.from.isETH {
      let amount = self.viewModel.amountFromBigInt
      let eth = KNSupportedTokenStorage.shared.ethToken
      KNGeneralProvider.shared.getExpectedRate(
        from: self.viewModel.from,
        to: eth,
        amount: amount) { [weak self] result in
        guard let `self` = self else { return }
        if case .success(let data) = result, amount == self.viewModel.amountFromBigInt {
          self.viewModel.updateEstimatedTokenRate(data.0, minRate: data.1)
          self.rateLabel.text = self.viewModel.exchangeRateText
          self.updateViewAmountDidChange()
        }
      }
    }
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

  func coordinatorUpdateBuyToken(_ token: TokenObject) {
    self.viewModel.updateBuyToken(token)

    self.fromTokenButton.setAttributedTitle(
      self.viewModel.tokenButtonAttributedText(isSource: true),
      for: .normal
    )
    self.fromTokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )

    self.buyAmountTextField.text = ""
    self.reloadDataFromNode()
    self.updateBalanceAndRate()
    self.updateViewAmountDidChange()
  }

  func coordinatorDidUpdateEstRate(for ieo: IEOObject, rate: BigInt) {
    if ieo.contract == self.viewModel.to.contract {
      self.viewModel.updateEstimateETHRate(rate)
      self.rateLabel.text = self.viewModel.exchangeRateText
      self.updateViewAmountDidChange()
    }
  }

  func coordinatorDidUpdateWalletObjects() {
    guard let walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.viewModel.walletObject.address) else { return }
    self.viewModel.updateWallet(walletObject)
    self.selectWalletButton.setTitle(self.viewModel.walletButtonTitle, for: .normal)
  }

  func coordinatorDidConfirmContribute() {
    // Reset view
    self.buyAmountTextField.text = ""
    self.receivedAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.updateViewAmountDidChange()
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
    if textField == self.buyAmountTextField, text.fullBigInt(decimals: self.viewModel.from.decimals) == nil { return false }
    if textField == self.receivedAmountTextField, text.fullBigInt(decimals: self.viewModel.to.tokenDecimals) == nil { return false }
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
    if !self.buyAmountTextField.isFirstResponder {
      self.buyAmountTextField.textColor = self.viewModel.amountTextFieldColor
    }
  }
}

// MARK: Toolbar delegate
extension IEOBuyTokenViewController: KNCustomToolbarDelegate {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardAllButtonPressed(toolbar)
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}
