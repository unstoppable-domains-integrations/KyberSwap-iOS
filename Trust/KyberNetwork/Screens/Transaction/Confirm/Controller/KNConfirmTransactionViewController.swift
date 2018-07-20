// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KNConfirmTransactionViewEvent {
  case cancel
  case confirm(type: KNTransactionType)
}

protocol KNConfirmTransactionViewControllerDelegate: class {
  func confirmTransactionViewController(_ controller: KNConfirmTransactionViewController, run event: KNConfirmTransactionViewEvent)
}

struct KNConfirmTransactionViewModel {
  let type: KNTransactionType
  init(type: KNTransactionType) {
    self.type = type
  }

  var leftButtonTitle: String {
    switch self.type {
    case .transfer: return "SEND"
    case .exchange: return "SWAP"
    case .buyTokenSale: return "CONTRIBUTE"
    }
  }

  var leftButtonIcon: String {
    return type.isTransfer ? "" : "kyber_icon_black"
  }

  var rightButtonTitle: String { return "Cancel".toBeLocalised() }

  var transactionDataTopPadding: CGFloat { return type.isTransfer ? 38.0 : 56.0 }
  var leftAmountLabelText: String {
    switch type {
    case .transfer(let tx):
      let token = tx.transferType.tokenObject()
      return tx.value.string(decimals: token.decimals, minFractionDigits: 4, maxFractionDigits: 4) + " \(token.symbol)"
    case .exchange(let trans):
      return trans.amount.string(decimals: trans.from.decimals, minFractionDigits: 4, maxFractionDigits: 4) + " \(trans.from.symbol)"
    case .buyTokenSale(let trans):
      return trans.amount.string(
        decimals: trans.token.decimals,
        minFractionDigits: 4,
        maxFractionDigits: 4
      ) + " \(trans.token.symbol)"
    }
  }

  var rightLabelAttributedText: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let highlightedAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 20)!,
      NSAttributedStringKey.foregroundColor: UIColor(hex: "000000"),
    ]
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont(name: "SFProText-Regular", size: 17)!,
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
    ]
    switch type {
    case .transfer(let tx):
      let address = tx.to?.description.lowercased() ?? ""
      let displayedAddress = "\(address.prefix(7))..\(address.suffix(5))"
      if let contact = KNContactStorage.shared.get(forPrimaryKey: address) {
        attributedString.append(NSAttributedString(string: contact.name, attributes: highlightedAttributes))
        attributedString.append(NSAttributedString(string: "\n\(displayedAddress)", attributes: normalAttributes))
      } else {
        attributedString.append(NSAttributedString(string: displayedAddress, attributes: highlightedAttributes))
      }
    case .exchange(let trans):
      let receivedAmount = "\(trans.displayExpectedReceive(short: true)) \(trans.to.symbol)"
      attributedString.append(NSAttributedString(string: receivedAmount, attributes: highlightedAttributes))
    case .buyTokenSale(let trans):
      let receivedAmount = "\(trans.displayExpectedReceived) \(trans.ieo.tokenSymbol)"
      attributedString.append(NSAttributedString(string: receivedAmount, attributes: highlightedAttributes))
    }
    return attributedString
  }

  var estimatedRateTopPadding: CGFloat { return type.isTransfer ? 40.0 : 30 }
  var heightForEstimatedRate: CGFloat { return type.isTransfer ? 0.0 : 52.0 }
  var isEstimatedRateHidden: Bool { return type.isTransfer }
  var displayEstimatedRate: String {
    switch self.type {
    case .exchange(let trans):
      let rateString = trans.expectedRate.string(decimals: trans.to.decimals, minFractionDigits: 6, maxFractionDigits: 6)
      return "1 \(trans.from.symbol) = \(rateString) \(trans.to.symbol)"
    case .buyTokenSale(let trans):
      let rateString = trans.estRate?.string(decimals: trans.ieo.tokenDecimals, minFractionDigits: 0, maxFractionDigits: 6) ?? "0"
      return "1 \(trans.token.symbol) = \(rateString) \(trans.ieo.tokenSymbol)"
    default: return ""
    }
  }
  var isSlippageRateHidden: Bool {
    return self.type.isTransfer
  }
  var heightForSlippageRate: CGFloat {
    return self.isSlippageRateHidden ? 0.0 : 52.0
  }
  var slippageRateString: String {
    if case .exchange(let trans) = type, let minRate = trans.minRate {
      let percentage = ((trans.expectedRate - minRate) * BigInt(100) / trans.expectedRate)
      return percentage.string(decimals: 0, minFractionDigits: 2, maxFractionDigits: 2) + " %"
    } else if case .buyTokenSale(let trans) = self.type, let estRate = trans.estRate, let minRate = trans.minRate {
      let percentage = ((estRate - minRate) * BigInt(100) / estRate)
      return percentage.string(decimals: 0, minFractionDigits: 2, maxFractionDigits: 2) + " %"
    }
    return ""
  }

  var feeString: String {
    switch type {
    case .transfer(let tx):
      let gasPrice = tx.gasPrice ?? KNGasConfiguration.gasPriceDefault
      let gasLimit: BigInt = {
        if let limit = tx.gasLimit { return limit }
        return tx.transferType.tokenObject().isETH ? KNGasConfiguration.transferETHGasLimitDefault : KNGasConfiguration.transferTokenGasLimitDefault
      }()
      let fee = gasPrice * gasLimit
      return fee.string(units: .ether, minFractionDigits: 6, maxFractionDigits: 6) + " ETH"
    case .exchange(let trans):
      let fee = (trans.gasPrice ?? BigInt(0)) * (trans.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault)
      return fee.string(units: .ether, minFractionDigits: 6, maxFractionDigits: 6) + " ETH"
    case .buyTokenSale(let trans):
      let fee = trans.gasPrice * trans.gasLimit
      return fee.string(units: .ether, minFractionDigits: 6, maxFractionDigits: 6) + " ETH"
    }
  }
}

class KNConfirmTransactionViewController: UIViewController {

  fileprivate let confirmTransactionCellID = "confirmTransactionCellID"
  fileprivate var viewModel: KNConfirmTransactionViewModel

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var leftButton: UIButton!
  @IBOutlet weak var rightButton: UIButton!

  @IBOutlet weak var transactionDataTopPaddingConstraint: NSLayoutConstraint!
  @IBOutlet weak var leftAmountLabel: UILabel!
  @IBOutlet weak var rightDataLabel: UILabel!

  @IBOutlet weak var estimatedRateTopPaddingConstraint: NSLayoutConstraint!
  @IBOutlet weak var estRateContainerView: UIView!
  @IBOutlet weak var estRateLabel: UILabel!
  @IBOutlet weak var estRateHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var slippageRateLabel: UILabel!
  @IBOutlet weak var slippageRateHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var slippageRateContainerView: UIView!

  @IBOutlet weak var networkFeeLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!

  fileprivate var data: [(String, String)] = []

  weak var delegate: KNConfirmTransactionViewControllerDelegate?

  init(viewModel: KNConfirmTransactionViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNConfirmTransactionViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapToParentView(_:)))
    self.view.addGestureRecognizer(tapGesture)

    self.confirmButton.rounded(
      color: UIColor(hex: "31CB9E"),
      width: 1,
      radius: self.confirmButton.frame.height / 2.0
    )
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.leftButton.setTitle(self.viewModel.leftButtonTitle, for: .normal)
    self.leftButton.setImage(UIImage(named: self.viewModel.leftButtonIcon), for: .normal)
    self.rightButton.setTitle(self.viewModel.rightButtonTitle, for: .normal)

    self.transactionDataTopPaddingConstraint.constant = self.viewModel.transactionDataTopPadding
    self.leftAmountLabel.text = self.viewModel.leftAmountLabelText
    self.rightDataLabel.attributedText = self.viewModel.rightLabelAttributedText

    self.estimatedRateTopPaddingConstraint.constant = self.viewModel.estimatedRateTopPadding
    self.estRateLabel.text = self.viewModel.displayEstimatedRate
    self.estRateHeightConstraint.constant = self.viewModel.heightForEstimatedRate
    self.estRateContainerView.isHidden = self.viewModel.isEstimatedRateHidden

    self.slippageRateLabel.text = self.viewModel.slippageRateString
    self.slippageRateHeightConstraint.constant = self.viewModel.heightForSlippageRate
    self.slippageRateContainerView.isHidden = self.viewModel.isSlippageRateHidden

    self.networkFeeLabel.text = self.viewModel.feeString
    self.view.layoutIfNeeded()
  }

  func update(viewModel: KNConfirmTransactionViewModel) {
    self.viewModel = viewModel
    self.updateUI()
  }

  @objc func didTapToParentView(_ sender: UITapGestureRecognizer) {
    let touchPoint = sender.location(in: self.view)
    if touchPoint.x < self.containerView.frame.minX || touchPoint.x > self.containerView.frame.maxX ||
      touchPoint.y < self.containerView.frame.minY || touchPoint.y > self.containerView.frame.maxY {
      self.delegate?.confirmTransactionViewController(self, run: .cancel)
    }
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.delegate?.confirmTransactionViewController(self, run: .cancel)
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    self.delegate?.confirmTransactionViewController(self, run: .confirm(type: self.viewModel.type))
  }
}
