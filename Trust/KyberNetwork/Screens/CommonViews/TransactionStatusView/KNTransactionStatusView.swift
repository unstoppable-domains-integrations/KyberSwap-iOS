// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNTransactionStatus: String {
  case broadcasting = "Broadcasting"
  case mining = "Mining"
  case failed = "Failed"
  case success = "Success"
  case unknown = "Unknown"

  var statusDetails: String {
    switch self {
    case .broadcasting:
      return "Transaction being broadcast"
    case .mining:
      return "Transaction being mined"
    case .failed:
      return "Transaction failed"
    case .success:
      return "Transaction success"
    default:
      return "No transaction"
    }
  }

  var imageName: String {
    switch self {
    case .broadcasting, .mining: return "loading_icon"
    case .failed: return "fail"
    case .success: return "success"
    default: return ""
    }
  }
}

protocol KNTransactionStatusViewDelegate: class {
  func transactionStatusDidPressClose()
}

class KNTransactionStatusView: XibLoaderView {

  fileprivate var txHash: String?
  fileprivate var isAnimating: Bool = false

  @IBOutlet weak var loadingContainerView: UIView!
  @IBOutlet weak var loadingImageView: UIImageView!
  @IBOutlet weak var txStatusLabel: UILabel!
  @IBOutlet weak var txStatusDetailsLabel: UILabel!

  weak var delegate: KNTransactionStatusViewDelegate?
  fileprivate var status: KNTransactionStatus = .unknown

  override var isHidden: Bool {
    didSet {
      self.txHash = nil
    }
  }

  override func commonInit() {
    super.commonInit()
    self.loadingImageView.tintColor = .white
    self.loadingImageView.image = self.loadingImageView.image?.withRenderingMode(.alwaysTemplate)
    self.txStatusLabel.text = ""
    self.txStatusDetailsLabel.text = ""
    let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.viewDidSwipeDown(_:)))
    swipeDownGesture.direction = .down
    self.isUserInteractionEnabled = true
    self.addGestureRecognizer(swipeDownGesture)
  }

  func updateView(with status: KNTransactionStatus, txHash: String?) {
    if let oldTxHash = self.txHash, let newTxHash = txHash, oldTxHash != newTxHash { return }
    // after broadcasting, should be mining
    if self.status == .broadcasting, status != .mining { return }
    if self.txHash != nil && txHash == nil { return }
    self.txHash = txHash
    self.txStatusLabel.text = status.rawValue
    self.txStatusDetailsLabel.text = status.statusDetails
    self.loadingImageView.image = UIImage(named: status.imageName)?.withRenderingMode(.alwaysTemplate)
    if status == .broadcasting || status == .mining {
      self.isAnimating = true
      self.loadingImageView.startRotating()
    } else {
      self.isAnimating = false
      self.loadingImageView.stopRotating()
    }
    self.layoutIfNeeded()
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.delegate?.transactionStatusDidPressClose()
  }

  @objc func viewDidSwipeDown(_ sender: Any) {
    self.delegate?.transactionStatusDidPressClose()
  }

  func updateViewDidAppear() {
    if self.isAnimating {
      self.loadingImageView.startRotating()
    } else {
      self.loadingImageView.stopRotating()
    }
  }
}
