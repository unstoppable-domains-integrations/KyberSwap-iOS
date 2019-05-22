// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNConfirmLimitOrderViewControllerDelegate: class {
  func confirmLimitOrderViewControllerDidBack()
  func confirmLimitOrderViewController(_ controller: KNConfirmLimitOrderViewController, order: KNLimitOrder)
}

class KNConfirmLimitOrderViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var broadcastConditonTextLabel: UILabel!

  @IBOutlet weak var srcDataLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var destDataLabel: UILabel!
  @IBOutlet weak var explainDestAmountLabel: UILabel!

  @IBOutlet weak var separatorView: UIView!

  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueButton: UIButton!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  weak var delegate: KNConfirmLimitOrderViewControllerDelegate?

  let order: KNLimitOrder

  init(order: KNLimitOrder) {
    self.order = order
    super.init(nibName: KNConfirmLimitOrderViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let from = self.order.from
    let to = self.order.to
    let srcAmount = self.order.srcAmount
    let fee = self.order.fee
    let targetRate = self.order.targetRate

    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    self.navTitleLabel.text = "Confirm Order".toBeLocalised()

    self.broadcastConditonTextLabel.text = "Your transaction will be broadcasted when rate of \(self.order.from.symbol)/\(self.order.to.symbol) >= \(self.order.targetRate.displayRate(decimals: self.order.to.decimals))".toBeLocalised()

    self.srcDataLabel.text = "\(self.order.srcAmount.displayRate(decimals: self.order.from.decimals)) \(self.order.from.symbol)"

    self.toTextLabel.text = NSLocalizedString("to", value: "To", comment: "")

    let srcAmountString = srcAmount.displayRate(decimals: from.decimals)
    let feeAmountString = fee.displayRate(decimals: from.decimals)
    let rateString = targetRate.displayRate(decimals: to.decimals)
    let receivedAmount: BigInt = {
      let srcAfterFee = max(BigInt(0), srcAmount - fee)
      return srcAfterFee * targetRate / BigInt(10).power(from.decimals)
    }()

    self.destDataLabel.text = "\(receivedAmount.displayRate(decimals: to.decimals)) \(to.symbol)"
    self.explainDestAmountLabel.text = "(\(srcAmountString) - \(feeAmountString)) \(from.symbol) * \(rateString) = \(receivedAmount.displayRate(decimals: to.decimals)) \(to.symbol)"

    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.feeTextLabel.text = "Fee".toBeLocalised()
    self.feeValueButton.semanticContentAttribute = .forceRightToLeft
    self.feeValueButton.setTitle("\(feeAmountString) \(from.symbol)", for: .normal)

    self.confirmButton.setTitle(NSLocalizedString("confirm", value: "Confirm", comment: ""), for: .normal)
    self.confirmButton.rounded(
      radius: self.confirmButton.frame.height / 2.0
    )
    self.confirmButton.applyGradient()

    self.cancelButton.setTitle(NSLocalizedString("cancel", value: "Cancel", comment: ""), for: .normal)

  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyGradient()
    self.separatorView.removeSublayer(at: 0)
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "confirm_limit_order", customAttributes: ["action": "back"])
    self.navigationController?.popViewController(animated: true, completion: {
      self.delegate?.confirmLimitOrderViewControllerDidBack()
    })
  }

  @IBAction func feeValueButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "confirm_limit_order", customAttributes: ["action": "fee"])
    self.showTopBannerView(
      with: "",
      message: "Don't worry, you won't be charged now. You pay fee only when transaction is executed successfully.".toBeLocalised(),
      icon: UIImage(named: "info_blue_icon"),
      time: 2.0
    )
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "confirm_limit_order", customAttributes: ["action": "confirm"])
    self.delegate?.confirmLimitOrderViewController(self, order: self.order)
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "confirm_limit_order", customAttributes: ["action": "cancel"])
    self.navigationController?.popViewController(animated: true, completion: {
      self.delegate?.confirmLimitOrderViewControllerDidBack()
    })
  }
}
