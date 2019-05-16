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
  @IBOutlet weak var orderStatusLabel: UILabel!

  @IBOutlet weak var conditionTextLabel: UILabel!
  @IBOutlet weak var orderConditionLabel: UILabel!

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

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.containerView.rounded(radius: 5.0)
    self.headerContainerView.rounded(radius: 2.5)
    self.orderStatusLabel.rounded(radius: 2.5)
    self.conditionTextLabel.text = "Condition".toBeLocalised().uppercased()
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

  func updateCell(with order: KNOrderObject, isReset: Bool) {
    self.order = order
    self.pairValueLabel.text = "\(order.sourceToken)  ➞  \(order.destToken)"
    self.dateValueLabel.text = DateFormatterUtil.shared.limitOrderFormatter.string(from: order.dateToDisplay)
    switch order.state {
    case .open:
      self.orderStatusLabel.isHidden = false
      self.orderStatusLabel.text = "Open".toBeLocalised()
      self.orderStatusLabel.backgroundColor = UIColor.Kyber.shamrock
    case .filled:
      self.orderStatusLabel.isHidden = false
      self.orderStatusLabel.text = "Filled".toBeLocalised()
      self.orderStatusLabel.backgroundColor = UIColor.Kyber.blueGreen
    default:
      self.orderStatusLabel.isHidden = true
    }

    let rate = BigInt(order.targetPrice * pow(10.0, 18.0)).displayRate(decimals: 18)
    self.orderConditionLabel.text = ">= \(rate)"

    self.sourceValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: order.sourceAmount)) \(order.sourceToken)"
    self.destValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: order.sourceAmount * order.targetPrice)) \(order.destToken)"
    if order.state != .open {
      self.updateCancelButtonUI(isShowing: false, callFromSuper: true)
    } else {
      self.updateCancelButtonUI(isShowing: !isReset, callFromSuper: true)
    }
  }

  @objc func onSwipe(_ gesture: UISwipeGestureRecognizer) {
    if self.order != nil && self.order.state != .open { return }
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
    self.delegate?.limitOrderCollectionViewCell(self, cancelPressed: self.order)
  }
}
