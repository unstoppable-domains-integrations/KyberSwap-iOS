// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import MSCircularSlider

enum KNSelectedGasPriceType: Int {
  case fast = 0
  case medium = 1
  case slow = 2
  case custom = 3
}

protocol KNSetGasPriceViewControllerDelegate: class {
  // gasPrice: nil if user pressed back, chosen value if user pressed done
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?)
}

struct KNSetGasPriceViewModel {

  let gradientColors: [UIColor] = [
    UIColor(hex: "fad961"),
    UIColor(hex: "f9cb41"),
    UIColor(hex: "f76b1c"),
  ]

  var gasPrice: BigInt
  let estGasLimit: BigInt

  init(gasPrice: BigInt, estGasLimit: BigInt) {
    self.gasPrice = gasPrice
    self.estGasLimit = estGasLimit
  }

  var navTitleText: String {
    return "Gas Price".toBeLocalised()
  }

  var gasPriceText: String {
    return self.gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
  }

  var feeBigInt: BigInt {
    return self.gasPrice * self.estGasLimit
  }

  var feeText: String {
    return self.feeBigInt.shortString(
      units: UnitConfiguration.gasFeeUnit,
      maxFractionDigits: 6
    ) + " ETH"
  }

  var txFeeAttributedString: NSAttributedString {
    let textAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .regular),
    ]
    let feeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "0c3533"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .regular),
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "Transaction Fee  ", attributes: textAttributes))
    attributedString.append(NSAttributedString(string: self.feeText, attributes: feeAttributes))
    return attributedString
  }
}

class KNSetGasPriceViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var circleSlider: MSGradientCircularSlider!
  @IBOutlet weak var gasPriceLabel: UILabel!
  @IBOutlet weak var txFeeLabel: UILabel!

  weak var delegate: KNSetGasPriceViewControllerDelegate?
  fileprivate var viewModel: KNSetGasPriceViewModel

  init(viewModel: KNSetGasPriceViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSetGasPriceViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.containerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.25),
      offset: CGSize(width: 0, height: 7),
      opacity: 0.32,
      radius: 32
    )
  }

  fileprivate func setupUI() {
    self.containerView.rounded(radius: 4.0)
    self.navTitleLabel.text = self.viewModel.navTitleText

    let currentValue: Double = Double(self.viewModel.gasPrice / BigInt(UnitConfiguration.gasPriceUnit.rawValue))
    self.circleSlider.currentValue = currentValue
    self.circularSlider(self.circleSlider, valueChangedTo: currentValue, fromUser: false)
    self.circleSlider.delegate = self

    self.updateUI()
  }

  func updateViewModel(_ viewModel: KNSetGasPriceViewModel) {
    self.viewModel = viewModel
    self.updateUI()
  }

  fileprivate func updateUI() {
    if self.viewModel.gasPrice == KNGasConfiguration.gasPriceMax {
      // maximum gas price
      self.circleSlider.gradientColors = [self.viewModel.gradientColors[2], self.viewModel.gradientColors[2], self.viewModel.gradientColors[2]]
    } else {
      self.circleSlider.gradientColors = self.viewModel.gradientColors
    }
    self.circleSlider.layoutIfNeeded()
    self.gasPriceLabel.text = self.viewModel.gasPriceText
    self.txFeeLabel.attributedText = self.viewModel.txFeeAttributedString
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: nil)
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: nil)
    }
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: self.viewModel.gasPrice)
  }

  func coordinatorGasPriceCachedDidUpdate() {
  }
}

extension KNSetGasPriceViewController: MSCircularSliderDelegate {
  func circularSlider(_ slider: MSCircularSlider, startedTrackingWith value: Double) {
  }

  func circularSlider(_ slider: MSCircularSlider, endedTrackingWith value: Double) {
  }

  func circularSlider(_ slider: MSCircularSlider, valueChangedTo value: Double, fromUser: Bool) {
    self.viewModel.gasPrice = BigInt(ceil(value)) * BigInt(EthereumUnit.gwei.rawValue)
    self.updateUI()
  }
}
