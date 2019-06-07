// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KNConvertSuggestionViewEvent {
  case estimateGasLimit(from: TokenObject, to: TokenObject, amount: BigInt)
  case confirmSwap(transaction: KNDraftExchangeTransaction)
}

protocol KNConvertSuggestionViewControllerDelegate: class {
  func convertSuggestionViewController(_ controller: KNConvertSuggestionViewController, run event: KNConvertSuggestionViewEvent)
}

class KNConvertSuggestionViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet var separatorViews: [UIView]!
  @IBOutlet weak var descTextLabel: UILabel!

  @IBOutlet weak var yourAddressTextLabel: UILabel!
  @IBOutlet weak var addressValueLabel: UILabel!
  @IBOutlet weak var yourBalanceTextLabel: UILabel!
  @IBOutlet weak var balanceValueLabel: UILabel!

  @IBOutlet weak var amountContainerView: UIView!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var wethContainerView: UIView!

  @IBOutlet weak var convertButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  fileprivate(set) var address: String = ""
  fileprivate(set) var ethBalance: BigInt = BigInt(0)
  fileprivate(set) var wethBalance: BigInt = BigInt(0)

  var availableWETHBalance: BigInt {
    var balanceInOrder: BigInt = BigInt(0)
    let orders = KNLimitOrderStorage.shared.orders
      .filter({ return ($0.state == .open || $0.state == .inProgress) && $0.srcTokenSymbol == "WETH" })
      .map({ return $0.clone() })
    orders.forEach({
      balanceInOrder += BigInt($0.sourceAmount * pow(10.0, 18.0))
    })
    return max(BigInt(0), self.wethBalance - balanceInOrder)
  }

  fileprivate(set) var amountToConvert: BigInt = BigInt(0)
  fileprivate(set) var estGasLimit: BigInt = KNGasConfiguration.exchangeETHTokenGasLimitDefault

  let eth = KNSupportedTokenStorage.shared.ethToken
  let weth = KNSupportedTokenStorage.shared.wethToken

  fileprivate var timer: Timer?

  weak var delegate: KNConvertSuggestionViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })

    self.descTextLabel.text = "Your order can not be submitted because your WETH is not enough, please convert ETH to WETH to continue.".toBeLocalised()
    self.yourAddressTextLabel.text = "Your address".toBeLocalised()
    self.yourBalanceTextLabel.text = "Your available balance".toBeLocalised()

    self.wethContainerView.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.wethContainerView.frame.height / 2.0
    )
    self.amountContainerView.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.amountContainerView.frame.height / 2.0
    )

    self.convertButton.applyGradient()
    self.convertButton.rounded(radius: self.convertButton.frame.height / 2.0)
    self.convertButton.setTitle("Convert".toBeLocalised(), for: .normal)
    self.cancelButton.setTitle(NSLocalizedString("cancel", comment: ""), for: .normal)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
        self?.loadDataFromNode()
      }
    )
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.timer?.invalidate()
    self.timer = nil
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorViews.forEach({ $0.removeSublayer(at: 0) })
    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })
    self.convertButton.removeSublayer(at: 0)
    self.convertButton.applyGradient()
  }

  func updateAddress(_ address: String) {
    self.address = address
    self.addressValueLabel.text = "\(address.prefix(12))...\(address.suffix(8))"
  }

  func updateETHBalance(_ balance: BigInt) {
    self.ethBalance = balance

    let ethBalanceDisplay = "\(self.ethBalance.string(decimals: 18, minFractionDigits: 4, maxFractionDigits: 4)) ETH"
    let wethBalanceDisplay = "\(self.availableWETHBalance.string(decimals: 18, minFractionDigits: 4, maxFractionDigits: 4)) WETH"
    self.balanceValueLabel.text = "\(ethBalanceDisplay)\n\(wethBalanceDisplay)"
  }

  func updateWETHBalance(_ balances: [String: Balance]) {
    guard let weth = self.weth else { return }
    self.wethBalance = balances[weth.contract]?.value ?? BigInt(0)
    let ethBalanceDisplay = "\(self.ethBalance.string(decimals: 18, minFractionDigits: 4, maxFractionDigits: 4)) ETH"
    let wethBalanceDisplay = "\(self.availableWETHBalance.string(decimals: 18, minFractionDigits: 4, maxFractionDigits: 4)) WETH"
    self.balanceValueLabel.text = "\(ethBalanceDisplay)\n\(wethBalanceDisplay)"
  }

  func updateAmountToConvert(_ amount: BigInt) {
    self.amountToConvert = amount
    self.amountTextField.text = amount.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
  }

  func updateEstimateGasLimit(_ gasLimit: BigInt) {
    self.estGasLimit = gasLimit
  }

  fileprivate func loadDataFromNode() {
    guard let weth = self.weth else { return }
    let amount = self.amountTextField.text?.removeGroupSeparator().fullBigInt(decimals: 18) ?? BigInt(0)
    let event = KNConvertSuggestionViewEvent.estimateGasLimit(from: eth, to: weth, amount: amount)
    self.delegate?.convertSuggestionViewController(self, run: event)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "convert_ETH_WETH", customAttributes: ["action": "back"])
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func convertButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "convert_ETH_WETH", customAttributes: ["action": "convert", "amount": self.amountTextField.text ?? ""])
    guard let text = self.amountTextField.text, let amount = text.removeGroupSeparator().fullBigInt(decimals: 18), !amount.isZero else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid Amount", comment: ""),
        message: "Please enter a valid amount to convert".toBeLocalised(),
        time: 1.5
      )
      return
    }
    if amount > self.ethBalance {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("insufficient.eth", value: "Insufficient ETH", comment: ""),
        message: "Your ETH balance is not enough to make the transaction".toBeLocalised(),
        time: 1.5
      )
      return
    }
    let feeBigInt = KNGasCoordinator.shared.fastKNGas * self.estGasLimit
    if amount + feeBigInt > self.ethBalance {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("insufficient.eth", value: "Insufficient ETH", comment: ""),
        message: "You don't have enough ETH to pay for transaction fee of \(feeBigInt.displayRate(decimals: 18)) ETH".toBeLocalised(),
        time: 1.5
      )
      return
    }
    let exchange = KNDraftExchangeTransaction(
      from: self.eth,
      to: self.weth!,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: BigInt(10).power(18),
      minRate: BigInt(10).power(18) * BigInt(97) / BigInt(100),
      gasPrice: KNGasCoordinator.shared.fastKNGas,
      gasLimit: self.estGasLimit,
      expectedReceivedString: self.amountTextField.text?.removeGroupSeparator()
    )
    self.delegate?.convertSuggestionViewController(
      self,
      run: .confirmSwap(transaction: exchange)
    )
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "convert_ETH_WETH", customAttributes: ["action": "cancel"])
    self.navigationController?.popViewController(animated: true)
  }
}
