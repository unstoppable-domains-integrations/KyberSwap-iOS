// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNPendingTransactionStatusViewControllerDelegate: class {
  func pendingTransactionStatusVCUserDidClickClose()
  func pendingTransactionStatusVCUserDidClickMoreDetails()
}

class KNPendingTransactionStatusViewController: KNBaseViewController {

  fileprivate weak var delegate: KNPendingTransactionStatusViewControllerDelegate?
  fileprivate var transaction: Transaction!
  fileprivate var timer: Timer?

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var transactionStatusLabel: UILabel!

  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var transactionTypeLabel: UILabel!
  @IBOutlet weak var detailsTransactionTypeLabel: UILabel!

  @IBOutlet weak var estimateFeeTextLabel: UILabel!
  @IBOutlet weak var estimateFeeValueLabel: UILabel!

  @IBOutlet weak var transactionHashTextLabel: UILabel!
  @IBOutlet weak var transactionHashValueLabel: UILabel!

  @IBOutlet weak var transactionTimeTextLabel: UILabel!
  @IBOutlet weak var transactionTimeValueLabel: UILabel!

  @IBOutlet weak var moreDetailsButton: UIButton!
  @IBOutlet weak var closeButton: UIButton!

  init(delegate: KNPendingTransactionStatusViewControllerDelegate?, transaction: Transaction) {
    self.delegate = delegate
    self.transaction = transaction
    super.init(nibName: KNPendingTransactionStatusViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.shouldRotateIcon(_:)), userInfo: nil, repeats: true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.timer?.invalidate()
    self.timer = nil
  }

  fileprivate func setupUI() {
    self.closeButton.rounded(color: .white, width: 1.0, radius: 5.0)
    self.closeButton.setTitle("Close".uppercased().toBeLocalised(), for: .normal)

    self.moreDetailsButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.moreDetailsButton.setTitle("More Details".uppercased().toBeLocalised(), for: .normal)

    self.updateView()
  }

  func updateViewWithTransaction(_ transaction: Transaction) {
    self.transaction = transaction
    if self.transaction.state != .pending {
      self.timer?.invalidate()
      self.timer = nil
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
        self.updateView()
      })
    }
  }

  fileprivate func updateView() {
    if self.transaction == nil { return }
    self.estimateFeeTextLabel.text = "Actual Fee".toBeLocalised()

    let estimateFeeString: String = {
      let gasPrice = EtherNumberFormatter.full.number(from: self.transaction.gasPrice, units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
      let gasUsed = EtherNumberFormatter.full.number(from: self.transaction.gasUsed, units: UnitConfiguration.gasFeeUnit) ?? BigInt(0)
      let fee = gasPrice * gasUsed / BigInt(UnitConfiguration.gasFeeUnit.rawValue)
      var string = "ETH \(fee.fullString(units: UnitConfiguration.gasFeeUnit))"
      let ethToken = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.isETH })!
      if let rate = KNRateCoordinator.shared.usdRate(for: ethToken) {
        let usdValue = rate.rate * fee
        string = "\(string) ($\(usdValue.shortString(units: .ether)))"
      }
      return string
    }()

    self.estimateFeeValueLabel.text = estimateFeeString

    switch self.transaction.state {
    case .completed:
      self.iconImageView.image = UIImage(named: "success")
      self.transactionStatusLabel.text = "Transaction Completed".toBeLocalised()
      self.transactionStatusLabel.textColor = UIColor.green
    case .failed, .error:
      self.iconImageView.image = UIImage(named: "fail")
      self.transactionStatusLabel.text = "Transaction Failed".toBeLocalised()
      self.transactionStatusLabel.textColor = UIColor.red
    default:
      self.estimateFeeTextLabel.text = "Est. Fee".toBeLocalised()
      self.iconImageView.image = UIImage(named: "kn_splash_logo")
      self.transactionStatusLabel.text = "Transaction Processing".toBeLocalised()
      self.transactionStatusLabel.textColor = UIColor.orange
    }

    let local = self.transaction.localizedOperations.first!
    let from = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.address == local.from })!
    let to = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.address == local.to })!

    let amount = EtherNumberFormatter.full.number(from: self.transaction.value, decimals: from.decimal) ?? BigInt(0)
    let amountString: String = {
      var string = "\(from.symbol) \(self.transaction.value)"
      if let rate = KNRateCoordinator.shared.usdRate(for: from) {
        let usdValue = rate.rate * amount
        string = "\(string) \n($\(usdValue.shortString(units: .ether)))"
      }
      return string
    }()

    self.amountLabel.text = amountString

    let exchangeRate = EtherNumberFormatter.full.number(from: local.value, decimals: to.decimal) ?? BigInt(0)
    let expectedAmount = amount * exchangeRate / BigInt(10).power(to.decimal)
    self.transactionTypeLabel.text = "Exchange To".toBeLocalised()
    self.detailsTransactionTypeLabel.text = "\(to.symbol) \(expectedAmount.fullString(decimals: to.decimal))"

    self.transactionHashTextLabel.text = "Transaction Hash".toBeLocalised()
    self.transactionHashValueLabel.text = self.transaction.id

    self.transactionTimeTextLabel.text = "Transaction Time".toBeLocalised()
    let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd MMM yyyy, HH:mm:ss"
      return formatter
    }()
    self.transactionTimeValueLabel.text = dateFormatter.string(from: self.transaction.date)
    self.view.layoutIfNeeded()
  }

  @objc func shouldRotateIcon(_ sender: Any?) {
    if self.transaction == nil || self.transaction.state != .pending {
      self.timer?.invalidate()
      self.timer = nil
      return
    }

    self.iconImageView.rotate360Degrees(duration: 0.75, completionDelegate: nil)
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.delegate?.pendingTransactionStatusVCUserDidClickClose()
  }

  @IBAction func moreDetailsButtonPressed(_ sender: Any) {
    self.delegate?.pendingTransactionStatusVCUserDidClickMoreDetails()
  }
}
