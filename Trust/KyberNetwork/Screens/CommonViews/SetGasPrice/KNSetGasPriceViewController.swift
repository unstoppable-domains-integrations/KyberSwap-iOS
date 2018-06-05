// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNSetGasPriceViewControllerDelegate: class {
  // gasPrice: nil if user pressed back, chosen value if user pressed done
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?)
}

struct KNSetGasPriceViewModel {

  fileprivate var gasPrices: [BigInt] = [
    KNGasCoordinator.shared.lowKNGas,
    KNGasCoordinator.shared.standardKNGas,
    KNGasCoordinator.shared.fastKNGas,
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
    ) + "  Gwei"
  }

  var selectedGasPriceID: Int {
    return self.gasPrices.index(of: self.gasPrice) ?? 2
  }

  mutating func updateGasPrice(selectedTag: Int) {
    self.gasPrice = self.gasPrices[selectedTag]
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
      NSAttributedStringKey.foregroundColor: UIColor(hex: "141927"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .medium),
    ]
    let feeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "31cb9e"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .regular),
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "Transaction Fee ", attributes: textAttributes))
    attributedString.append(NSAttributedString(string: self.feeText, attributes: feeAttributes))
    return attributedString
  }

  mutating func shouldUpdateGasPriceDidChange() {
    self.gasPrices = [
      KNGasCoordinator.shared.lowKNGas,
      KNGasCoordinator.shared.standardKNGas,
      KNGasCoordinator.shared.fastKNGas,
    ]
    if self.gasPrices.index(of: self.gasPrice) == nil {
      self.gasPrice = self.gasPrices[2]
    }
  }
}

class KNSetGasPriceViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var gasPriceLabel: UILabel!
  @IBOutlet var gasTypeButtons: [UIButton]!
  @IBOutlet weak var txFeeLabel: UILabel!
  @IBOutlet weak var gasPriceExplainLabel: UILabel!

  @IBOutlet weak var doneButton: UIButton!

  weak var delegate: KNSetGasPriceViewControllerDelegate?
  fileprivate var viewModel: KNSetGasPriceViewModel

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(rawValue: kGasPriceDidUpdateNotificationKey),
      object: nil
    )
  }

  init(viewModel: KNSetGasPriceViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSetGasPriceViewController.className, bundle: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.shouldUpdateGasPrice(_:)),
      name: NSNotification.Name(rawValue: kGasPriceDidUpdateNotificationKey),
      object: nil
    )
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.updateUI()
  }

  fileprivate func setupUI() {
    self.gasTypeButtons.forEach {
      $0.rounded(
        color: UIColor(hex: "31cb9e"),
        width: 1,
        radius: $0.frame.height / 2.0
      )
      $0.setTitleColor(UIColor(hex: "141927"), for: .normal)
    }
    self.doneButton.rounded(radius: 7.0)
  }

  func updateViewModel(_ viewModel: KNSetGasPriceViewModel) {
    self.viewModel = viewModel
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.navTitleLabel.text = self.viewModel.navTitleText
    self.gasPriceLabel.text = self.viewModel.gasPriceText
    self.gasTypeButtons.forEach({
      let isSelected = $0.tag == self.viewModel.selectedGasPriceID
      let color = isSelected ? UIColor.white : UIColor(hex: "141927")
      $0.setTitleColor(color, for: .normal)
      $0.backgroundColor = isSelected ? UIColor(hex: "31cb9e") : .clear
    })
    self.txFeeLabel.attributedText = self.viewModel.txFeeAttributedString
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: nil)
  }

  @IBAction func gasPriceTypeButtonPressed(_ sender: UIButton) {
    if self.viewModel.selectedGasPriceID != sender.tag {
      self.viewModel.updateGasPrice(selectedTag: sender.tag)
      self.updateUI()
    }
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: self.viewModel.gasPrice)
  }

  @IBAction func screenEdgePanAction(_ sender: Any) {
    self.delegate?.setGasPriceViewControllerDidReturn(gasPrice: nil)
  }

  @objc func shouldUpdateGasPrice(_ sender: Notification?) {
    self.viewModel.shouldUpdateGasPriceDidChange()
    self.updateUI()
  }
}
