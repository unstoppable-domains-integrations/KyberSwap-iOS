// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNWalletTokenCollectionViewCellDelegate: class {
  func walletTokenCollectionViewCellDidClickExchange(token: KNToken)
  func walletTokenCollectionViewCellDidClickTransfer(token: KNToken)
  func walletTokenCollectionViewCellDidClickReceive(token: KNToken)
}

class KNWalletTokenCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kWalletTokenCollectionViewCell"
  static let normalHeight: CGFloat = 80.0
  static let expandedHeight: CGFloat = 125.0

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!

  @IBOutlet weak var tokenBalanceAmountLabel: UILabel!
  @IBOutlet weak var tokenUSDAmountLabel: UILabel!

  @IBOutlet weak var exchangeButton: UIButton!
  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var receiveButton: UIButton!

  @IBOutlet weak var bottomPaddingConstraint: NSLayoutConstraint!
  @IBOutlet weak var heightButtonConstraint: NSLayoutConstraint!

  fileprivate var token: KNToken!
  fileprivate weak var delegate: KNWalletTokenCollectionViewCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = UIColor.white
    self.rounded(color: .clear, width: 0, radius: 5.0)
    self.exchangeButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.transferButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.receiveButton.rounded(color: .clear, width: 0, radius: 5.0)
  }

  func updateCell(with token: KNToken, balance: Balance, isExpanded: Bool, delegate: KNWalletTokenCollectionViewCellDelegate?) {
    self.iconImageView.image = UIImage(named: token.icon)
    self.tokenNameLabel.text = token.symbol
    self.tokenBalanceAmountLabel.text = balance.amountShort
    if let usdRate = KNRateCoordinator.shared.usdRate(for: token) {
      let amountString: String = {
        return EtherNumberFormatter.short.string(from: usdRate.rate * balance.value)
      }()
      self.tokenUSDAmountLabel.text = "US$\(amountString)"
    } else {
      self.tokenUSDAmountLabel.text = "US$0.00"
    }
    self.token = token
    self.delegate = delegate
    if isExpanded {
      self.heightButtonConstraint.constant = 32
      self.bottomPaddingConstraint.constant = 15
    } else {
      self.heightButtonConstraint.constant = 0
      self.bottomPaddingConstraint.constant = 0
    }
    self.setNeedsUpdateConstraints()
    self.layoutIfNeeded()
  }

  @IBAction func exchangeButtonPressed(_ sender: UIButton) {
    self.delegate?.walletTokenCollectionViewCellDidClickExchange(token: self.token)
  }

  @IBAction func transferButtonPressed(_ sender: UIButton) {
    self.delegate?.walletTokenCollectionViewCellDidClickTransfer(token: self.token)
  }

  @IBAction func receiveButtonPressed(_ sender: UIButton) {
    self.delegate?.walletTokenCollectionViewCellDidClickReceive(token: self.token)
  }
}
