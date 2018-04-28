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
  @IBOutlet weak var iconTextLabel: UILabel!
  @IBOutlet weak var tokenNameLabel: UILabel!

  @IBOutlet weak var tokenBalanceAmountLabel: UILabel!
  @IBOutlet weak var tokenUSDAmountLabel: UILabel!

  @IBOutlet weak var exchangeButton: UIButton!
  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var receiveButton: UIButton!

  @IBOutlet weak var bottomPaddingConstraint: NSLayoutConstraint!
  @IBOutlet weak var heightButtonConstraint: NSLayoutConstraint!

  fileprivate var tokenObject: TokenObject!
  fileprivate weak var delegate: KNWalletTokenCollectionViewCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = UIColor.white
    self.rounded(color: .clear, width: 0, radius: 5.0)
    self.exchangeButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.transferButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.receiveButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.iconImageView.rounded(
      color: .clear,
      width: 0,
      radius: self.iconImageView.frame.width / 2.0
    )
    self.iconTextLabel.rounded(
      color: .clear,
      width: 0,
      radius: self.iconTextLabel.frame.width / 2.0
    )
  }

  func updateCell(with tokenObject: TokenObject, balance: Balance, isExpanded: Bool, delegate: KNWalletTokenCollectionViewCellDelegate?) {
    if let iconImage = UIImage(named: KNTokenStorage.iconImageName(for: tokenObject)) {
      self.iconImageView.image = iconImage
      self.iconImageView.isHidden = false
      self.iconTextLabel.isHidden = true
    } else {
      self.iconTextLabel.text = String(tokenObject.symbol.prefix(1)).uppercased()
      self.iconTextLabel.isHidden = false
      self.iconImageView.isHidden = true
    }

    self.tokenNameLabel.text = tokenObject.symbol
    self.tokenBalanceAmountLabel.text = balance.amountShort
    if let usdRate = KNRateCoordinator.shared.usdRate(for: tokenObject) {
      let amountString: String = {
        return EtherNumberFormatter.short.string(from: usdRate.rate * balance.value / BigInt(EthereumUnit.ether.rawValue)) 
      }()
      self.tokenUSDAmountLabel.text = "US$\(amountString)"
    } else {
      self.tokenUSDAmountLabel.text = "US$0"
    }
    self.tokenObject = tokenObject
    self.delegate = delegate
    if isExpanded {
      self.heightButtonConstraint.constant = 32
      self.bottomPaddingConstraint.constant = 12
    } else {
      self.heightButtonConstraint.constant = 0
      self.bottomPaddingConstraint.constant = 0
    }
    self.layoutIfNeeded()
  }

  @IBAction func exchangeButtonPressed(_ sender: UIButton) {
    //TODO: Temporary
    if let token = KNJSONLoaderUtil.shared.tokens.first(where: { $0.address == self.tokenObject.contract }) {
      self.delegate?.walletTokenCollectionViewCellDidClickExchange(token: token)
    }
  }

  @IBAction func transferButtonPressed(_ sender: UIButton) {
    if let token = KNJSONLoaderUtil.shared.tokens.first(where: { $0.address == self.tokenObject.contract }) {
      self.delegate?.walletTokenCollectionViewCellDidClickTransfer(token: token)
    }
  }

  @IBAction func receiveButtonPressed(_ sender: UIButton) {
    if let token = KNJSONLoaderUtil.shared.tokens.first(where: { $0.address == self.tokenObject.contract }) {
      self.delegate?.walletTokenCollectionViewCellDidClickReceive(token: token)
    }
  }
}
