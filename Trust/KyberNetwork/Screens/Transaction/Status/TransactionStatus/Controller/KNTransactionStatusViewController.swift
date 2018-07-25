// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNTransactionStatusViewControllerDelegate: class {
  func transactionStatusVCUserDidClickClose()
  func transactionStatusVCUserDidTapToView(transaction: Transaction)
}

class KNTransactionStatusViewController: KNBaseViewController {

  fileprivate weak var delegate: KNTransactionStatusViewControllerDelegate?
  fileprivate var transaction: Transaction?

  @IBOutlet weak var transactionStatusView: KNTransactionStatusView!

  init(delegate: KNTransactionStatusViewControllerDelegate?, transaction: Transaction?) {
    self.delegate = delegate
    self.transaction = transaction
    super.init(nibName: KNTransactionStatusViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.transactionStatusView.updateViewWillAppear()
  }

  fileprivate func setupUI() {
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    self.transactionStatusView.rounded(color: UIColor.Kyber.lightGray, width: 0.1, radius: 4.0)
    self.transactionStatusView.delegate = self
    self.updateViewWithTransaction(self.transaction)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewDidTap(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  func updateViewWithTransaction(_ transaction: Transaction?, error: String? = nil) {
    if let err = error {
      // Broadcasting error
      self.transactionStatusView.updateView(with: .broadcastingError, txHash: transaction?.id, details: err)
      return
    }
    self.transaction = transaction
    let status: KNTransactionStatus = {
      guard let tran = transaction else { return .broadcasting }
      if tran.state == .pending { return .pending }
      if tran.state == .failed { return .failed }
      if tran.state == .completed { return .success }
      return .unknown
    }()
    // TODO: Get details when transaction is success/fail
    let details: String? = {
      guard let object = transaction?.localizedOperations.first, status == .failed || status == .success else { return nil }
      guard let from = KNSupportedTokenStorage.shared.get(forPrimaryKey: object.from) else { return nil }
      guard let amount = transaction?.value.fullBigInt(decimals: from.decimals) else { return nil }
      if object.type.lowercased() == "transfer" {
        return "\(status.rawValue) sent \(amount.shortString(decimals: from.decimals, maxFractionDigits: 6)) \(from.symbol) to \n\(transaction?.to ?? "")"
      }
      guard let to = KNSupportedTokenStorage.shared.get(forPrimaryKey: object.to) else { return nil }
      guard let expectedAmount = object.value.fullBigInt(decimals: object.decimals) else { return nil }
      return "\(status.rawValue) \(amount.shortString(decimals: from.decimals, maxFractionDigits: 6)) \(from.symbol) converted to \(expectedAmount.shortString(decimals: object.decimals, maxFractionDigits: 6)) \(to.symbol)"
    }()
    self.transactionStatusView.updateView(with: status, txHash: transaction?.id, details: details)
  }

  @objc func viewDidTap(_ sender: UITapGestureRecognizer) {
    let touchPoint = sender.location(in: self.view)
    if touchPoint.x < self.transactionStatusView.frame.minX || touchPoint.x > self.transactionStatusView.frame.maxX
      || touchPoint.y < self.transactionStatusView.frame.minY || touchPoint.y > self.transactionStatusView.frame.maxY {
      self.delegate?.transactionStatusVCUserDidClickClose()
    }
  }
}

extension KNTransactionStatusViewController: KNTransactionStatusViewDelegate {
  func transactionStatusDidPressClose() {
    self.delegate?.transactionStatusVCUserDidClickClose()
  }

  func transactionStatusDidPressView() {
    guard let trans = self.transaction else { return }
    self.delegate?.transactionStatusVCUserDidTapToView(transaction: trans)
  }
}
