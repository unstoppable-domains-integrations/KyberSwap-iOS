// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNLimitOrderCollectionViewCellDelegate: class {
  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, cancelPressed order: KNOrderObject)
}

class KNLimitOrderCollectionViewCell: UICollectionViewCell {

  static let height: CGFloat = 115.0
  static let cellID: String = "kLimitOrderCollectionViewCell"

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var pairValueLabel: UILabel!
  @IBOutlet weak var dateValueLabel: UILabel!
  @IBOutlet weak var orderStatusLabel: UIButton!

  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueLabel: UILabel!

  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var sourceValueLabel: UILabel!

  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var destValueLabel: UILabel!
  @IBOutlet weak var leadingSpaceToContainerViewConstraint: NSLayoutConstraint!
  @IBOutlet weak var trailingSpaceToContainerViewConstraint: NSLayoutConstraint!

  @IBOutlet weak var cancelButton: UIButton!

  weak var delegate: KNLimitOrderCollectionViewCellDelegate?

  var pan: UIPanGestureRecognizer!
  var order: KNOrderObject!
  var hasAction: Bool = true

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.containerView.rounded(radius: 5.0)
    self.headerContainerView.rounded(radius: 2.5)
    self.orderStatusLabel.rounded(radius: self.orderStatusLabel.frame.height / 2.0)
    self.feeTextLabel.text = "Fee".toBeLocalised().uppercased()
    self.fromTextLabel.text = NSLocalizedString("From", value: "From", comment: "").uppercased()
    self.toTextLabel.text = NSLocalizedString("To", value: "To", comment: "").uppercased()
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: "").uppercased(),
      for: .normal
    )

    let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.onSwipe(_:)))
    swipeLeftGesture.direction = .left
    self.addGestureRecognizer(swipeLeftGesture)

    let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.onSwipe(_:)))
    swipeRightGesture.direction = .right
    self.addGestureRecognizer(swipeRightGesture)
  }

  func updateCell(with order: KNOrderObject, isReset: Bool, hasAction: Bool = true) {
    self.order = order
    self.hasAction = hasAction

    let rate = BigInt(order.targetPrice * pow(10.0, 18.0)).displayRate(decimals: 18)

    let srcTokenSymbol = order.srcTokenSymbol
    let destTokenSymbol = order.destTokenSymbol

    self.pairValueLabel.text = "\(srcTokenSymbol)  ➞  \(destTokenSymbol) >= \(rate)"

    self.dateValueLabel.text = DateFormatterUtil.shared.limitOrderFormatter.string(from: order.dateToDisplay)
    self.orderStatusLabel.isHidden = false
    switch order.state {
    case .open:
      self.orderStatusLabel.setTitle("Open".toBeLocalised(), for: .normal)
      self.orderStatusLabel.backgroundColor = UIColor.Kyber.shamrock
    case .inProgress:
      self.orderStatusLabel.setTitle("In progress".toBeLocalised(), for: .normal)
      self.orderStatusLabel.backgroundColor = UIColor(red: 248, green: 159, blue: 80)
    case .filled:
      self.orderStatusLabel.setTitle("Filled".toBeLocalised(), for: .normal)
      self.orderStatusLabel.backgroundColor = UIColor.Kyber.blueGreen
    case .cancelled:
      self.orderStatusLabel.setTitle("Cancelled".toBeLocalised(), for: .normal)
      self.orderStatusLabel.backgroundColor = UIColor(red: 190, green: 190, blue: 190)
    case .invalidated:
      self.orderStatusLabel.setTitle("Invalidated".toBeLocalised(), for: .normal)
      self.orderStatusLabel.backgroundColor = UIColor(red: 70, green: 73, blue: 80)
    default:
      self.orderStatusLabel.isHidden = true
    }
    let feeDisplay: String = {
      let feeDouble = order.fee * order.sourceAmount
      return BigInt(feeDouble * pow(10.0, 18.0)).displayRate(decimals: 18)
    }()
    self.feeValueLabel.text = "\(feeDisplay) \(srcTokenSymbol)"

    self.sourceValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: order.sourceAmount)) \(srcTokenSymbol)"
    self.destValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: order.sourceAmount * order.targetPrice)) \(destTokenSymbol)"
    if hasAction {
      if order.state != .open {
        self.updateCancelButtonUI(isShowing: false, callFromSuper: true)
      } else {
        self.updateCancelButtonUI(isShowing: !isReset, callFromSuper: true)
      }
    }
  }

  @objc func onSwipe(_ gesture: UISwipeGestureRecognizer) {
    if self.order != nil && self.order.state != .open { return }
    if !self.hasAction { return }
    if gesture.state == .ended {
      self.updateCancelButtonUI(isShowing: gesture.direction == .left)
    }
  }

  fileprivate func updateCancelButtonUI(isShowing: Bool, callFromSuper: Bool = false) {
    if isShowing {
      UIView.animate(withDuration: 0.25, animations: {
          self.cancelButton.isHidden = false
          self.leadingSpaceToContainerViewConstraint.constant = -96
          self.trailingSpaceToContainerViewConstraint.constant = 120
          self.layoutIfNeeded()
      }, completion: { _ in
        if self.order != nil {
          self.delegate?.limitOrderCollectionViewCell(self, cancelPressed: self.order)
        }
      })
    } else {
      self.cancelButton.isHidden = true
      self.layoutIfNeeded()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        UIView.animate(withDuration: 0.16) {
          self.trailingSpaceToContainerViewConstraint.constant = 12
          self.leadingSpaceToContainerViewConstraint.constant = 12
          self.layoutIfNeeded()
        }
      }
    }
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    if self.order == nil { return }
    if !self.hasAction { return }
    self.delegate?.limitOrderCollectionViewCell(self, cancelPressed: self.order)
  }
}
