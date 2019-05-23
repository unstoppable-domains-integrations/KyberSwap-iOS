// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNConvertSuggestionViewControllerDelegate: class {
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
  fileprivate(set) var balance: BigInt = BigInt(0)
  fileprivate(set) var amountToConvert: BigInt = BigInt(0)

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })

    self.descTextLabel.text = "Your order can not be submitted because your WETH is not enough, please convert ETH to WETH to continue.".toBeLocalised()
    self.yourAddressTextLabel.text = "Your address".toBeLocalised()
    self.yourBalanceTextLabel.text = "Your balance".toBeLocalised()

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
    self.balance = balance
    self.balanceValueLabel.text = "\(balance.string(decimals: 18, minFractionDigits: 4, maxFractionDigits: 4)) ETH"
  }

  func updateAmountToConvert(_ amount: BigInt) {
    self.amountToConvert = amount
    self.amountTextField.text = amount.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
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
    if amount > self.balance {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid Amount", comment: ""),
        message: "Your balance is not enough to make the transaction".toBeLocalised(),
        time: 1.5
      )
      return
    }
    let feeBigInt = KNGasCoordinator.shared.fastKNGas * KNGasConfiguration.exchangeETHTokenGasLimitDefault
    if amount + feeBigInt > self.balance {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid Amount", comment: ""),
        message: "You don't have enough ETH to pay for transaction fee of \(feeBigInt.displayRate(decimals: 18)) ETH".toBeLocalised(),
        time: 1.5
      )
      return
    }
    self.showSuccessTopBannerMessage(with: "Success", message: "Your convert transaction has been broadcasted", time: 1.5)
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "convert_ETH_WETH", customAttributes: ["action": "cancel"])
    self.navigationController?.popViewController(animated: true)
  }
}
