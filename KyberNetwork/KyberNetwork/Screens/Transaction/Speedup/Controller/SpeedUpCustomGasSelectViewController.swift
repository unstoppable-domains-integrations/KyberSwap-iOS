// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum SpeedUpCustomGasSelectViewEvent {
  case back
  case done(transaction: Transaction, newGasPrice: BigInt)
  case invaild
}

protocol SpeedUpCustomGasSelectDelegate: class {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent)
}

class SpeedUpCustomGasSelectViewController: KNBaseViewController {
  @IBOutlet weak var navigationTitleLabel: UILabel!
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var superFastGasPriceButton: UIButton!
  @IBOutlet weak var superFastGasPriceLabel: UILabel!
  @IBOutlet weak var fastGasPriceButton: UIButton!
  @IBOutlet weak var fastGasPriceLabel: UILabel!
  @IBOutlet weak var regularGasPriceButton: UIButton!
  @IBOutlet weak var regularGasPriceLabel: UILabel!
  @IBOutlet weak var slowGasPriceButton: UIButton!
  @IBOutlet weak var slowGasPriceLabel: UILabel!
  @IBOutlet weak var currentFeeLabel: UILabel!
  @IBOutlet weak var newFeeLabel: UILabel!
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var gasFeeSelectBoxContainer: UIView!
  @IBOutlet weak var mainTextTitle: UILabel!
  @IBOutlet weak var currentFeeTitleLabel: UILabel!
  @IBOutlet weak var newFeeTitleLabel: UILabel!
  @IBOutlet weak var gasPriceWarningMessageLabel: UILabel!
  fileprivate let viewModel: SpeedUpCustomGasSelectViewModel
  weak var delegate: SpeedUpCustomGasSelectDelegate?

  init(viewModel: SpeedUpCustomGasSelectViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SpeedUpCustomGasSelectViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    updateUI()
    updateGasPriceUIs()
  }

  fileprivate func updateUI() {
    navigationTitleLabel.text = "Customize Gas".toBeLocalised()
    mainTextTitle.text = "Select.higher.tx.fee.to.accelerate".toBeLocalised()
    gasPriceWarningMessageLabel.text = "your.gas.must.be.10.percent.higher".toBeLocalised()
    currentFeeLabel.text = "Current fee".toBeLocalised()
    newFeeLabel.text = "New fee".toBeLocalised()
    doneButton.setTitle("done".toBeLocalised(), for: .normal)
    headerView.applyGradient(with: UIColor.Kyber.headerColors)
    gasFeeSelectBoxContainer.rounded(radius: 5.0)
    superFastGasPriceButton.backgroundColor = .white
    fastGasPriceButton.backgroundColor = .white
    regularGasPriceButton.backgroundColor = .white
    slowGasPriceButton.backgroundColor = .white
    let tapSuperFast = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSelectBoxLabel(_:)))
    superFastGasPriceLabel.addGestureRecognizer(tapSuperFast)
    let tapFast = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSelectBoxLabel(_:)))
    fastGasPriceLabel.addGestureRecognizer(tapFast)
    let tapRegular = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSelectBoxLabel(_:)))
    regularGasPriceLabel.addGestureRecognizer(tapRegular)
    let tapSlow = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSelectBoxLabel(_:)))
    slowGasPriceLabel.addGestureRecognizer(tapSlow)
    currentFeeLabel.text = viewModel.currentTransactionFeeETHString
    let style = KNAppStyleType.current
    let radius = style.buttonRadius(for: doneButton.frame.height)
    doneButton.rounded(radius: radius)
    doneButton.applyGradient()
  }

  func updateGasPriceUIs() {
    self.superFastGasPriceLabel.attributedText = self.viewModel.superFastGasString
    self.fastGasPriceLabel.attributedText = self.viewModel.fastGasString
    self.regularGasPriceLabel.attributedText = self.viewModel.mediumGasString
    self.slowGasPriceLabel.attributedText = self.viewModel.slowGasString

    let selectedColor = UIColor.Kyber.enygold
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.superFastGasPriceButton.rounded(
      color: self.viewModel.selectedType == .superFast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .superFast ? selectedWidth : normalWidth,
      radius: self.superFastGasPriceButton.frame.height / 2.0
    )

    self.fastGasPriceButton.rounded(
      color: self.viewModel.selectedType == .fast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .fast ? selectedWidth : normalWidth,
      radius: self.fastGasPriceButton.frame.height / 2.0
    )

    self.regularGasPriceButton.rounded(
      color: self.viewModel.selectedType == .medium ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .medium ? selectedWidth : normalWidth,
      radius: self.regularGasPriceButton.frame.height / 2.0
    )

    self.slowGasPriceButton.rounded(
      color: self.viewModel.selectedType == .slow ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .slow ? selectedWidth : normalWidth,
      radius: self.slowGasPriceButton.frame.height / 2.0
    )
    newFeeLabel.text = viewModel.getNewTransactionFeeETHString()
  }

  @IBAction func doneButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "tap_done_button_in_custom_gas_price_select_screen", customAttributes: ["transactionHash": viewModel.transaction.id])
    if viewModel.isNewGasPriceValid() {
      delegate?.speedUpCustomGasSelectViewController(self, run: .done(transaction: viewModel.transaction, newGasPrice: viewModel.getNewTransactionGasPriceETH()))
    } else {
      delegate?.speedUpCustomGasSelectViewController(self, run: .invaild)
    }
  }
  @IBAction func backButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "tap_back_button_in_custom_gas_price_select_screen", customAttributes: ["transactionHash": viewModel.transaction.id])
    delegate?.speedUpCustomGasSelectViewController(self, run: .back)
  }
  @objc func userTappedSelectBoxLabel(_ sender: UITapGestureRecognizer) {
    guard let type = KNSelectedGasPriceType(rawValue: sender.view!.tag) else { return }
    handleGasFeeChange(type)
  }
  @IBAction func selectBoxButtonTapped(_ sender: UIButton) {
    guard let type = KNSelectedGasPriceType(rawValue: sender.tag) else { return }
    KNCrashlyticsUtil.logCustomEvent(withName: "tap_option_button_in_custom_gas_price_select_screen", customAttributes: ["transactionHash": viewModel.transaction.id, "option": type])
    handleGasFeeChange(type)
  }
  func handleGasFeeChange(_ type: KNSelectedGasPriceType) {
    viewModel.updateSelectedType(type)
    updateGasPriceUIs()
  }
}
