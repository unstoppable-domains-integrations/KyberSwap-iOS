// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNTokenBalanceCollectionViewCellDelegate: class {
  func tokenBalanceCollectionViewCellExchangeButtonPressed(for tokenObject: TokenObject)
  func tokenBalanceCollectionViewCellSendButtonPressed(for tokenObject: TokenObject)
}

struct KNTokenBalanceCollectionViewCellModel {
  let token: TokenObject
  let icon: String?
  let coinTicker: KNCoinTicker?
  let balance: Balance?

  init(
    token: TokenObject,
    icon: String?,
    coinTicker: KNCoinTicker?,
    balance: Balance?
    ) {
    self.token = token
    self.icon = icon
    self.coinTicker = coinTicker
    self.balance = balance
  }

  var displayBalance: String {
    if let amount = balance?.value.shortString(decimals: token.decimals) {
      return "\(amount) \(token.symbol)"
    }
    return ""
  }

  var backgroundColorBalance: UIColor {
    return balance == nil ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.white
  }

  var displayBalanceInUSD: String {
    if let amount = balance?.value, let coinTicker = coinTicker {
      let rate = KNRate.rateUSD(from: coinTicker)
      return "$\((amount * rate.rate / BigInt(10).power(self.token.decimals)).shortString(units: .ether, maxFractionDigits: 2))"
    }
    return ""
  }

  var backgroundColorBalanceInUSD: UIColor {
    return balance == nil || coinTicker == nil ? UIColor.lightGray.withAlphaComponent(0.25) : UIColor.white
  }

  var displayChange24h: String {
    if let percentageChange = coinTicker?.percentChange24h, !percentageChange.isEmpty {
      return "\(percentageChange)%"
    }
    return ""
  }

  var colorChange24h: UIColor {
    if let percentageChange = coinTicker?.percentChange24h.prefix(1) {
      return String(percentageChange) == "-" ? UIColor(hex: "d0021b") : UIColor(hex: "5ec2ba")
    }
    return UIColor(hex: "5ec2ba")
  }

  var backgroundColorChange24h: UIColor {
    return coinTicker == nil || coinTicker?.percentChange24h.isEmpty == true ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.white
  }

  var displayPrice: String {
    if let priceUSD = coinTicker?.priceUSD {
      return "$\(priceUSD.displayUSD())"
    }
    return ""
  }

  var backgroundColorPrice: UIColor {
    return coinTicker == nil ? UIColor.lightGray.withAlphaComponent(0.25) : UIColor.white
  }

  var displayKyberListed: String {
    return self.token.isSupported ? "Kyber Listed".toBeLocalised() : ""
  }
}

class KNTokenBalanceCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kTokenBalanceCollectionCellID"
  static let cellHeight: CGFloat = 90

  @IBOutlet weak var tokenDataContainerView: UIView!
  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenFakeIcon: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var tokenBalanceInUSDLabel: UILabel!

  @IBOutlet weak var tokenChange24hLabel: UILabel!
  @IBOutlet weak var tokenPriceLabel: UILabel!
  @IBOutlet weak var kyberListedLabel: UILabel!

  @IBOutlet weak var buttonContainerView: UIView!
  @IBOutlet weak var exchangeButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!

  fileprivate var cellModel: KNTokenBalanceCollectionViewCellModel?

  weak var delegate: KNTokenBalanceCollectionViewCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenDataContainerView.isHidden = true
    self.buttonContainerView.isHidden = false
    // Token data view
    self.tokenBalanceLabel.text = ""
    self.tokenBalanceInUSDLabel.text = ""

    self.tokenChange24hLabel.text = ""
    self.tokenPriceLabel.text = ""
    self.kyberListedLabel.text = ""

    self.tokenFakeIcon.rounded(
      color: .clear,
      width: 0,
      radius: 12.0
    )
    self.tokenFakeIcon.isHidden = true

    // Button view
    self.exchangeButton.rounded(color: .clear, width: 0, radius: 4.0)
    self.sendButton.rounded(color: .clear, width: 0, radius: 4.0)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.contentView.rounded(color: .clear, width: 0, radius: 4.0)
    self.layer.shadowColor = UIColor.black.cgColor
    self.layer.shadowOffset = CGSize(width: 0, height: 2)
    self.layer.shadowOpacity = 0.16
    self.layer.shadowRadius = 1
    self.layer.masksToBounds = false
    self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    self.layer.shouldRasterize = true
    self.layer.rasterizationScale = UIScreen.main.scale
    self.layer.cornerRadius = 4.0
  }

  func updateCell(with cellModel: KNTokenBalanceCollectionViewCellModel, isSelected: Bool) {
    self.cellModel = cellModel
    if let icon = cellModel.icon, let image = UIImage(named: icon) {
      self.tokenIconImageView.image = image
      self.tokenIconImageView.isHidden = false
      self.tokenFakeIcon.isHidden = true
    } else {
      self.tokenIconImageView.isHidden = true
      self.tokenFakeIcon.isHidden = false
      self.tokenFakeIcon.text = String(cellModel.token.symbol.prefix(1))
    }

    self.tokenBalanceLabel.text = cellModel.displayBalance
    self.tokenBalanceLabel.backgroundColor = cellModel.backgroundColorBalance

    self.tokenBalanceInUSDLabel.text = cellModel.displayBalanceInUSD
    self.tokenBalanceInUSDLabel.backgroundColor = cellModel.backgroundColorBalanceInUSD

    self.tokenChange24hLabel.text = cellModel.displayChange24h
    self.tokenChange24hLabel.textColor = cellModel.colorChange24h
    self.tokenChange24hLabel.backgroundColor = cellModel.backgroundColorChange24h

    self.tokenPriceLabel.text = cellModel.displayPrice
    self.tokenPriceLabel.backgroundColor = cellModel.backgroundColorPrice

    self.kyberListedLabel.text = cellModel.displayKyberListed
    if isSelected {
      // only flip if it is hidden
      if self.buttonContainerView.isHidden {
        UIView.animate(
          withDuration: 0.5,
          delay: 0,
          options: .transitionFlipFromTop,
          animations: { },
          completion: { _ in
          self.tokenDataContainerView.isHidden = true
          self.buttonContainerView.isHidden = false
        })
      }
    } else if self.tokenDataContainerView.isHidden {
      // only flip back when it is hidden
      UIView.animate(
        withDuration: 0.5,
        delay: 0,
        options: .transitionFlipFromTop,
        animations: { },
        completion: { _ in
          self.tokenDataContainerView.isHidden = false
          self.buttonContainerView.isHidden = true
      })
    }
    self.layoutIfNeeded()
  }

  @IBAction func exchangeButtonPressed(_ sender: Any) {
    guard let tokenObject = self.cellModel?.token else { return }
    self.delegate?.tokenBalanceCollectionViewCellExchangeButtonPressed(for: tokenObject)
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    guard let tokenObject = self.cellModel?.token else { return }
    self.delegate?.tokenBalanceCollectionViewCellSendButtonPressed(for: tokenObject)
  }
}
