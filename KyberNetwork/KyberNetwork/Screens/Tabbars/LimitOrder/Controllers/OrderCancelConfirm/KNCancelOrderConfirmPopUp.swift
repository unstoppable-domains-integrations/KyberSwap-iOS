// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNCancelOrderConfirmPopUp: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleTextLabel: UILabel!

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var pairValueLabel: UILabel!
  @IBOutlet weak var dateValueLabel: UILabel!
  @IBOutlet weak var statusValueLabel: UIButton!

  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueLabel: UILabel!

  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var sourceValueLabel: UILabel!

  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var destValueLabel: UILabel!

  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var confirmButton: UIButton!

  let order: KNOrderObject

  init(order: KNOrderObject) {
    self.order = order
    super.init(nibName: KNCancelOrderConfirmPopUp.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.containerView.rounded(radius: 8.0)
    self.headerContainerView.rounded(radius: 2.5)
    self.statusValueLabel.rounded(radius: 2.5)

    self.titleTextLabel.text = "You are cancelling this order".toBeLocalised()
    self.feeTextLabel.text = "Fee".toBeLocalised().uppercased()
    self.fromTextLabel.text = NSLocalizedString("From", value: "From", comment: "").uppercased()
    self.toTextLabel.text = NSLocalizedString("To", value: "To", comment: "").uppercased()
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: "").uppercased(),
      for: .normal
    )
    self.cancelButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.cancelButton.frame.height / 2.0
    )
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: "").uppercased(),
      for: .normal
    )
    self.confirmButton.rounded(radius: self.confirmButton.frame.height / 2.0)
    self.confirmButton.applyGradient()

    let srcTokenSymbol = order.srcTokenSymbol
    let destTokenSymbol = order.destTokenSymbol
    let rate = BigInt(order.targetPrice * pow(10.0, 18.0)).displayRate(decimals: 18)

    self.pairValueLabel.text = "\(srcTokenSymbol)  ➞  \(destTokenSymbol) >= \(rate)"
    self.dateValueLabel.text = DateFormatterUtil.shared.limitOrderFormatter.string(from: order.dateToDisplay)
    switch order.state {
    case .open:
      self.statusValueLabel.setTitle("Open".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor.Kyber.shamrock
    case .inProgress:
      self.statusValueLabel.setTitle("In progress".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 248, green: 159, blue: 80)
    case .filled:
      self.statusValueLabel.setTitle("Filled".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor.Kyber.blueGreen
    case .cancelled:
      self.statusValueLabel.setTitle("Cancelled".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 190, green: 190, blue: 190)
    case .invalidated:
      self.statusValueLabel.setTitle("Invalidated".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 70, green: 73, blue: 80)
    default:
      self.statusValueLabel.isHidden = true
    }

    let feeDisplay: String = {
      let feeDouble = Double(order.fee) / 10000.0 * order.sourceAmount
      return BigInt(feeDouble * pow(10.0, 18.0)).displayRate(decimals: 18)
    }()
    self.feeValueLabel.text = "\(feeDisplay) \(srcTokenSymbol)"

    self.sourceValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: order.sourceAmount)) \(srcTokenSymbol)"
    self.destValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: order.sourceAmount * order.targetPrice)) \(destTokenSymbol)"
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyGradient()
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    self.displayLoading(text: "Cancelling".toBeLocalised(), animated: true)
    KNLimitOrderServerCoordinator.shared.cancelOrder(
      accessToken: accessToken,
      orderID: order.id) { [weak self] result in
        guard let `self` = self else { return }
        self.hideLoading()
        switch result {
        case .success:
          self.dismiss(animated: true, completion: nil)
          self.showSuccessTopBannerMessage(with: "Success", message: "Your order has been cancelled", time: 1.5)
        case .failure(let error):
          self.displayError(error: error)
        }
    }
  }
}
