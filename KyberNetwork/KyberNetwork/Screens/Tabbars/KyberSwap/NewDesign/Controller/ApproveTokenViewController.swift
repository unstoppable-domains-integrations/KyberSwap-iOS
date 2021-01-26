//
//  ApproveTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/25/20.
//

import UIKit
import BigInt

protocol ApproveTokenViewModel {
  func getGasLimit() -> BigInt
  func getFee() -> BigInt
  func getFeeString() -> String
  func getFeeUSDString() -> String
  var subTitleText: String { get }
  var token: TokenObject? { get }
  var remain: BigInt { get }
  var address: String { get }
  var state: Bool { get }
}

class ApproveTokenViewModelForTokenObject: ApproveTokenViewModel {
  let token: TokenObject?
  let remain: BigInt
  var gasPrice: BigInt = KNGasCoordinator.shared.defaultKNGas

  func getGasLimit() -> BigInt {
    if let gasApprove = self.token?.gasApproveDefault { return gasApprove }
    return KNGasConfiguration.approveTokenGasLimitDefault
  }

  func getFee() -> BigInt {
    let gasLimit = self.getGasLimit()
    let fee = self.gasPrice * gasLimit
    return fee
  }

  func getFeeString() -> String {
    let fee = self.getFee()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) ETH"
  }

  func getFeeUSDString() -> String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
    let value: BigInt = usdRate * self.getFee() / BigInt(EthereumUnit.ether.rawValue)
    let valueString: String = value.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var subTitleText: String {
    return String(format: "You need to grant permission for Krytal to interact with %@ with this Address:", self.token?.symbol.uppercased() ?? "")
  }

  var address: String {
    return self.token?.address ?? ""
  }
  
  var state: Bool {
    return false
  }

  init(token: TokenObject, res: BigInt) {
    self.token = token
    self.remain = res
  }
}

class ApproveTokenViewModelForGasToken: ApproveTokenViewModel {
  var token: TokenObject?
  let address: String
  let remain: BigInt
  var gasPrice: BigInt = KNGasCoordinator.shared.defaultKNGas
  let state: Bool

  init(address: String, remain: BigInt, state: Bool) {
    self.address = address
    self.remain = remain
    self.state = state
  }

  func getGasLimit() -> BigInt {
    return KNGasConfiguration.approveTokenGasLimitDefault
  }

  func getFee() -> BigInt {
    let gasLimit = self.getGasLimit()
    let fee = self.gasPrice * gasLimit
    return fee
  }

  func getFeeString() -> String {
    let fee = self.getFee()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) ETH"
  }

  func getFeeUSDString() -> String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
    let value: BigInt = usdRate * self.getFee() / BigInt(EthereumUnit.ether.rawValue)
    let valueString: String = value.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var subTitleText: String {
    return "You need to grant permission for Krytal to interact with CHI with this Address:".toBeLocalised()
  }
}

protocol ApproveTokenViewControllerDelegate: class {
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt)
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool)
}

class ApproveTokenViewController: KNBaseViewController {
  @IBOutlet weak var headerTitle: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var contractAddressLabel: UILabel!
  @IBOutlet weak var gasFeeTitleLabel: UILabel!
  @IBOutlet weak var gasFeeLabel: UILabel!
  @IBOutlet weak var gasFeeEstUSDLabel: UILabel!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var approveButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let viewModel: ApproveTokenViewModel
  let transitor = TransitionDelegate()
  weak var delegate: ApproveTokenViewControllerDelegate?

  init(viewModel: ApproveTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ApproveTokenViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.gasFeeLabel.text = self.viewModel.getFeeString()
    self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
    self.cancelButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: 16)
    self.approveButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.descriptionLabel.text = self.viewModel.subTitleText
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.approveButton.removeSublayer(at: 0)
    self.approveButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }

  @IBAction func approveButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      if let token = self.viewModel.token {
        self.delegate?.approveTokenViewControllerDidApproved(self, token: token, remain: self.viewModel.remain)
      } else {
        self.delegate?.approveTokenViewControllerDidApproved(self, address: self.viewModel.address, remain: self.viewModel.remain, state: self.viewModel.state)
      }
    })
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension ApproveTokenViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 350
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
