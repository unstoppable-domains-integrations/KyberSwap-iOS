//
//  WithdrawConfirmPopupViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/8/21.
//

import UIKit
import BigInt

class WithdrawConfirmPopupViewModel {
  let balance: LendingBalance
  
  init(balance: LendingBalance) {
    self.balance = balance
  }
  
  var balanceBigInt: BigInt {
    return BigInt(self.balance.supplyBalance) ?? BigInt(0)
  }
  
  var displayBalance: NSAttributedString {
    let balanceString = self.balanceBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: 6)
    let rateString = String(format: "%.2f", self.balance.supplyRate * 100)
    let amountAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let apyAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: "\(balanceString) \(self.balance.symbol) ", attributes: amountAttributes))
    attributedText.append(NSAttributedString(string: "\(rateString)% APY", attributes: apyAttributes))
    return attributedText
  }
  
  var valueBigInt: BigInt {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.balance.address) else { return BigInt(0) }
    let price = tokenPrice.usd
    return self.balanceBigInt * BigInt(price * pow(10.0, 18.0)) / BigInt(10).power(18)
  }
  
  var displayValue: String {
    let string = self.valueBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: 6)
    return "$" + string
  }
  
  var symbol: String {
    return self.balance.symbol
  }
}

protocol WithdrawConfirmPopupViewControllerDelegate: class {
  func withdrawConfirmPopupViewControllerDidSelectFirstButton(_ controller: WithdrawConfirmPopupViewController)
  func withdrawConfirmPopupViewControllerDidSelectSecondButton(_ controller: WithdrawConfirmPopupViewController)
}

class WithdrawConfirmPopupViewController: KNBaseViewController {
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  let viewModel: WithdrawConfirmPopupViewModel
  weak var delegate: WithdrawConfirmPopupViewControllerDelegate?
  
  init(viewModel: WithdrawConfirmPopupViewModel) {
    self.viewModel = viewModel
    super.init(nibName: WithdrawConfirmPopupViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.firstButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.firstButton.frame.size.height / 2)
    self.secondButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.secondButton.frame.size.height / 2)
    self.iconImageView.setSymbolImage(symbol: self.viewModel.symbol, size: CGSize(width: 17, height: 17))
    self.balanceLabel.attributedText = self.viewModel.displayBalance
    self.valueLabel.text = self.viewModel.displayValue
  }

  @IBAction func firstButtonTapped(_ sender: Any) {
    self.delegate?.withdrawConfirmPopupViewControllerDidSelectFirstButton(self)
  }
  
  @IBAction func secondButtonTapped(_ sender: Any) {
    self.delegate?.withdrawConfirmPopupViewControllerDidSelectSecondButton(self)
  }
}

extension WithdrawConfirmPopupViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 190
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
