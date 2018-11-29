// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KAdvancedSettingsViewEvent {
  case infoPressed
  case displayButtonPressed
  case gasPriceChanged(type: KNSelectedGasPriceType)
  case minRatePercentageChanged(percent: CGFloat)
}

protocol KAdvancedSettingsViewDelegate: class {
  func kAdvancedSettingsView(_ view: KAdvancedSettingsView, run event: KAdvancedSettingsViewEvent)
}

class KAdvancedSettingsViewModel: NSObject {

  private let kGasPriceContainerHeight: CGFloat = 210
  private let kMinRateContainerHeight: CGFloat = 160

  fileprivate(set) var fast: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var medium: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var slow: BigInt = KNGasCoordinator.shared.lowKNGas
  fileprivate(set) var gasLimit: BigInt = BigInt(0)

  fileprivate(set) var selectedType: KNSelectedGasPriceType = .medium

  fileprivate(set) var isViewHidden: Bool = true
  fileprivate(set) var hasMinRate: Bool = true

  let brandColor: UIColor

  fileprivate(set) var minRateString: String?
  fileprivate(set) var minRatePercent: CGFloat?

  init(hasMinRate: Bool, brandColor: UIColor) {
    self.hasMinRate = hasMinRate
    self.brandColor = brandColor
  }

  var isGasPriceViewHidden: Bool { return self.isViewHidden }
  var gasPriceViewHeight: CGFloat { return self.isGasPriceViewHidden ? 0 : kGasPriceContainerHeight }

  var fastGasString: NSAttributedString {
    return self.attributedString(for: self.fast)
  }
  var mediumGasString: NSAttributedString {
    return self.attributedString(for: self.medium)
  }
  var slowGasString: NSAttributedString {
    return self.attributedString(for: self.slow)
  }

  func attributedString(for gasPrice: BigInt) -> NSAttributedString {
    let gasPriceString: String = gasPrice.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2)
    let feeString: String = {
      let fee: BigInt = gasPrice * self.gasLimit
      let string = fee.string(units: .ether, minFractionDigits: 0, maxFractionDigits: 9)
      return " (~\(string.prefix(12)) ETH)"
    }()
    let gasPriceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.mirage,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
    ]
    let feeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: gasPriceString, attributes: gasPriceAttributes))
    attributedString.append(NSAttributedString(string: feeString, attributes: feeAttributes))
    return attributedString
  }

  var isMinRateViewHidden: Bool { return !self.hasMinRate || self.isViewHidden }
  var minRateViewHeight: CGFloat { return self.isMinRateViewHidden ? 0 : kMinRateContainerHeight }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt) {
    self.fast = fast
    self.medium = medium
    self.slow = slow
  }

  func updateSelectedType(_ type: KNSelectedGasPriceType) {
    self.selectedType = type
  }

  func updateGasLimit(_ gasLimit: BigInt) {
    self.gasLimit = gasLimit
  }

  func updateViewHidden(isHidden: Bool) { self.isViewHidden = isHidden }

  func updateMinRateValue(_ value: String, percent: CGFloat) {
    self.minRateString = value
    self.minRatePercent = percent
  }

  func updateHasMinRate(hasMinRate: Bool) { self.hasMinRate = hasMinRate }

  var totalHeight: CGFloat {
    var height: CGFloat = 20.0 + 24.0 + 10.0 // top padding, button control height, bottom padding
    height += self.gasPriceViewHeight
    height += self.minRateViewHeight
    return height
  }
}

class KAdvancedSettingsView: XibLoaderView {

  @IBOutlet weak var topSeparatorView: UIView!
  @IBOutlet weak var displayViewButton: UIButton!

  @IBOutlet weak var heightConstraintGasPriceContainerView: NSLayoutConstraint!
  @IBOutlet weak var gasPriceContainerView: UIView!
  @IBOutlet weak var gasFeeGweiTextLabel: UILabel!
  @IBOutlet weak var fasGasValueLabel: UILabel!
  @IBOutlet weak var fasGasButton: UIButton!
  @IBOutlet weak var fastTextLabel: UILabel!
  @IBOutlet weak var fastGasFeeTapView: UIView!

  @IBOutlet weak var mediumGasValueLabel: UILabel!
  @IBOutlet weak var mediumGasButton: UIButton!
  @IBOutlet weak var mediumTextLabel: UILabel!
  @IBOutlet weak var mediumGasFeeTapView: UIView!

  @IBOutlet weak var slowGasValueLabel: UILabel!
  @IBOutlet weak var slowGasButton: UIButton!
  @IBOutlet weak var slowTextLabel: UILabel!
  @IBOutlet weak var slowGasFeeTapView: UIView!
  @IBOutlet weak var gasPriceSeparatorView: UIView!

  @IBOutlet weak var minRateContainerView: UIView!
  @IBOutlet weak var minAcceptableRateTextLabel: UILabel!
  @IBOutlet weak var heightConstraintMinRateContainerView: NSLayoutConstraint!
  @IBOutlet weak var minRateValueLabel: UILabel!

  @IBOutlet weak var leadingConstraintForMinRatePercentLabel: NSLayoutConstraint!
  @IBOutlet weak var minRatePercentLabel: UILabel!
  @IBOutlet weak var minRateSlider: CustomSlider!
  @IBOutlet weak var minRateSeparatorView: UIView!

  fileprivate var viewModel: KAdvancedSettingsViewModel!
  weak var delegate: KAdvancedSettingsViewDelegate?

  var height: CGFloat {
    if self.viewModel == nil { return 20.0 + 24.0 + 10.0 }
    return self.viewModel.totalHeight
  }

  var isExpanded: Bool { return !self.viewModel.isViewHidden }

  override func commonInit() {
    super.commonInit()
    self.topSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.gasFeeGweiTextLabel.text = NSLocalizedString("gas.fee.gwei", value: "GAS fee (Gwei)", comment: "")
    self.gasPriceSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.minRateSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.minAcceptableRateTextLabel.text = NSLocalizedString("min.acceptable.rate", value: "Min Acceptable Rate", comment: "")
    self.leadingConstraintForMinRatePercentLabel.constant = 0.0
    self.minRateValueLabel.text = "0"
    self.minRatePercentLabel.text = "0 %"
    self.minRateSlider.value = 0.0

    self.minRateSlider.addTarget(self, action: #selector(self.minRateSliderDidChange(_:)), for: .valueChanged)
    self.fastTextLabel.text = NSLocalizedString("fast", value: "Fast", comment: "").uppercased()
    self.mediumTextLabel.text = NSLocalizedString("standard", value: "Standard", comment: "").uppercased()
    self.slowTextLabel.text = NSLocalizedString("slow", value: "Slow", comment: "").uppercased()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.topSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.gasPriceSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.minRateSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  func updateViewModel(_ viewModel: KAdvancedSettingsViewModel) {
    self.viewModel = viewModel
    self.updateGasPriceUIs()
    self.updateMinRateUIs()
    self.minRateValueLabel.textColor = viewModel.brandColor
    self.minRateSlider.minimumTrackTintColor = viewModel.brandColor
    self.minRateSlider.thumbTintColor = viewModel.brandColor
  }

  fileprivate func updateGasPriceUIs() {
    if self.viewModel == nil { return }
    self.gasPriceContainerView.isHidden = self.viewModel.isGasPriceViewHidden
    self.heightConstraintGasPriceContainerView.constant = self.viewModel.gasPriceViewHeight

    self.fasGasValueLabel.attributedText = self.viewModel.fastGasString
    self.mediumGasValueLabel.attributedText = self.viewModel.mediumGasString
    self.slowGasValueLabel.attributedText = self.viewModel.slowGasString

    let selectedColor = self.viewModel.brandColor
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 8.0
    let normalWidth: CGFloat = 1.0

    self.fasGasButton.rounded(
      color: self.viewModel.selectedType == .fast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .fast ? selectedWidth : normalWidth,
      radius: self.fasGasButton.frame.height / 2.0
    )

    self.mediumGasButton.rounded(
      color: self.viewModel.selectedType == .medium ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .medium ? selectedWidth : normalWidth,
      radius: self.mediumGasButton.frame.height / 2.0
    )

    self.slowGasButton.rounded(
      color: self.viewModel.selectedType == .slow ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .slow ? selectedWidth : normalWidth,
      radius: self.slowGasButton.frame.height / 2.0
    )

    let tapFast = UITapGestureRecognizer(target: self, action: #selector(self.userTappedFastFee(_:)))
    self.fastGasFeeTapView.addGestureRecognizer(tapFast)

    let tapMedium = UITapGestureRecognizer(target: self, action: #selector(self.userTappedMediumFee(_:)))
    self.mediumGasFeeTapView.addGestureRecognizer(tapMedium)

    let tapSlow = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSlowFee(_:)))
    self.slowGasFeeTapView.addGestureRecognizer(tapSlow)

    self.updateConstraintsIfNeeded()
    self.layoutIfNeeded()
  }

  fileprivate func updateMinRateUIs() {
    if self.viewModel == nil { return }
    self.minRateContainerView.isHidden = self.viewModel.isMinRateViewHidden
    self.heightConstraintMinRateContainerView.constant = self.viewModel.minRateViewHeight

    if self.minRateContainerView.isHidden { return }
    self.minRateSlider.value = Float(self.viewModel.minRatePercent ?? 0.0)
    self.minRatePercentLabel.text = "\(Float(self.viewModel.minRatePercent ?? 0.0)) %"
    self.minRateValueLabel.text = self.viewModel.minRateString ?? "0.0"

    self.leadingConstraintForMinRatePercentLabel.constant = (self.minRateSlider.frame.width - 40.0) * (self.viewModel.minRatePercent ?? 0.0) / 100.0
    self.updateConstraints()
    self.layoutSubviews()
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, gasLimit: BigInt) {
    if self.viewModel == nil { return }
    self.viewModel.updateGasPrices(fast: fast, medium: medium, slow: slow)
    self.viewModel.updateGasLimit(gasLimit)
    self.updateGasPriceUIs()
  }

  func updateHasMinRate(_ hasMinRate: Bool) {
    if self.viewModel == nil { return }
    self.viewModel.updateHasMinRate(hasMinRate: hasMinRate)
    self.updateMinRateUIs()
  }

  func updateMinRate(_ value: String, percent: CGFloat) {
    if self.viewModel == nil { return }
    self.viewModel.updateMinRateValue(value, percent: percent)
    self.updateMinRateUIs()
  }

  @IBAction func displayViewButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    let isHidden = !self.viewModel.isViewHidden
    self.viewModel.updateViewHidden(isHidden: isHidden)
    self.displayViewButton.setImage(
      UIImage(named: isHidden ? "expand_icon" : "collapse_icon"),
      for: .normal
    )
    self.updateGasPriceUIs()
    self.updateMinRateUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .displayButtonPressed)
  }

  @objc func minRateSliderDidChange(_ sender: CustomSlider) {
    let percent = CGFloat(sender.value)
    let event = KAdvancedSettingsViewEvent.minRatePercentageChanged(percent: percent)
    self.delegate?.kAdvancedSettingsView(self, run: event)
  }

  @IBAction func infoButtonPressed(_ sender: Any) {
    self.delegate?.kAdvancedSettingsView(self, run: .infoPressed)
  }

  @IBAction func fastGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.fast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .fast))
  }

  @IBAction func mediumGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.medium)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .medium))
  }

  @IBAction func slowGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.slow)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .slow))
  }

  @objc func userTappedFastFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.fast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .fast))
  }

  @objc func userTappedMediumFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.medium)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .medium))
  }

  @objc func userTappedSlowFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.slow)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .slow))
  }
}
