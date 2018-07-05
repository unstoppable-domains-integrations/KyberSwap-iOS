// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KNTokenBalanceCollectionViewCellModel {

  fileprivate let highlighted: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor(hex: "141927"),
    NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 16)!,
  ]
  fileprivate let normal: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor(hex: "adb6ba"),
    NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 12)!,
  ]

  let token: TokenObject
  let icon: String?
  let coinTicker: KNCoinTicker?
  let balance: Balance?
  let ethCoinTicker: KNCoinTicker?

  var displayedType: KNBalanceDisplayDataType = .eth

  init(
    token: TokenObject,
    icon: String?,
    coinTicker: KNCoinTicker?,
    balance: Balance?,
    ethCoinTicker: KNCoinTicker?,
    displayedType: KNBalanceDisplayDataType
    ) {
    self.token = token
    self.icon = icon
    self.coinTicker = coinTicker
    self.balance = balance
    self.ethCoinTicker = ethCoinTicker
    self.displayedType = displayedType
  }

  fileprivate var displayBalanceHoldingsText: String {
    if let amount = balance?.value.string(decimals: token.decimals, minFractionDigits: 2, maxFractionDigits: 6) {
      return "Bal \(amount.prefix(11))"
    }
    return "Bal ---"
  }

  fileprivate var displayBalanceInUSD: String {
    if let amount = balance?.value, let coinTicker = coinTicker {
      let rate = KNRate.rateUSD(from: coinTicker)
      let value = (amount * rate.rate / BigInt(10).power(self.token.decimals)).string(units: .ether, minFractionDigits: 2, maxFractionDigits: 2)
      return "Val $\(value.prefix(11))"
    }
    return "Val ---"
  }

  fileprivate var displayBalanceInETH: String {
    if let amount = balance?.value, let coinTicker = coinTicker, let ethCoinTicker = ethCoinTicker {
      let rateETH = coinTicker.priceUSD / ethCoinTicker.priceUSD
      let rate = KNRate(
        source: self.token.symbol,
        dest: "ETH",
        rate: rateETH,
        decimals: 18
      )
      let value = (amount * rate.rate / BigInt(10).power(self.token.decimals)).string(units: .ether, minFractionDigits: 4, maxFractionDigits: 9)
      return "Val \(value.prefix(11))"
    }
    return "Val ---"
  }

  var displayTokenPriceAttributedText: NSAttributedString {
    let value: String = {
      if self.displayedType == .eth {
        return self.displayBalanceInETH
      }
      return self.displayBalanceInUSD
    }()
    let rate: BigInt? = {
      if self.displayedType == .usd {
        if let coinTicker = self.coinTicker {
          return KNRate.rateUSD(from: coinTicker).rate
        }
        return nil
      }
      if let coinTicker = coinTicker, let ethCoinTicker = ethCoinTicker {
        let rateETH = coinTicker.priceUSD / ethCoinTicker.priceUSD
        let rate = KNRate(
          source: self.token.symbol,
          dest: "ETH",
          rate: rateETH,
          decimals: 18
        )
        return rate.rate
      }
      return nil
    }()
    let attributedString = NSMutableAttributedString()
    let rateString = rate?.string(units: .ether, minFractionDigits: 4, maxFractionDigits: 9) ?? "-.--"
    attributedString.append(NSAttributedString(string: "\(rateString.prefix(11))", attributes: highlighted))
    attributedString.append(NSAttributedString(string: "\n\(value.prefix(11))", attributes: normal))
    return attributedString
  }

  var tokenValueAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(self.token.symbol) ", attributes: highlighted))
    attributedString.append(NSAttributedString(string: self.displayedType == .eth ? "/ ETH" : "/ USD", attributes: normal))
    attributedString.append(NSAttributedString(string: "\n\(self.displayBalanceHoldingsText)", attributes: normal))
    return attributedString
  }

  var displayChange24h: String {
    if let percentageChange = coinTicker?.percentChange24h, !percentageChange.isEmpty {
      return "\(percentageChange)%"
    }
    return "- - - - - -"
  }

  var textColorChange24h: UIColor {
    if let percentageChange = coinTicker?.percentChange24h.prefix(1) {
      return String(percentageChange) == "-" ? UIColor(hex: "f89f50") : UIColor(hex: "31cb9e")
    }
    return UIColor(hex: "5a5e67")
  }

  var backgroundColorChange24h: UIColor {
    if let percentageChange = coinTicker?.percentChange24h.prefix(1) {
      return String(percentageChange) == "-" ? UIColor(hex: "fef6ef") : UIColor(hex: "edfbf6")
    }
    return UIColor.white
  }
}

class KNTokenBalanceCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kTokenBalanceCollectionCellID"
  static let cellHeight: CGFloat = 56

  @IBOutlet weak var tokenDataContainerView: UIView!
  @IBOutlet weak var tokenValueLabel: UILabel!

  @IBOutlet weak var tokenChange24hLabel: UILabel!
  @IBOutlet weak var tokenPriceLabel: UILabel!

  fileprivate var cellModel: KNTokenBalanceCollectionViewCellModel?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenValueLabel.text = ""
    self.tokenPriceLabel.text = ""
    self.tokenChange24hLabel.text = ""
    self.tokenChange24hLabel.rounded(radius: 2.0)
  }

  func updateCell(with cellModel: KNTokenBalanceCollectionViewCellModel) {
    self.cellModel = cellModel

    self.tokenValueLabel.attributedText = cellModel.tokenValueAttributedString

    self.tokenChange24hLabel.text = cellModel.displayChange24h
    self.tokenChange24hLabel.textColor = cellModel.textColorChange24h
    self.tokenChange24hLabel.backgroundColor = cellModel.backgroundColorChange24h

    self.tokenPriceLabel.attributedText = cellModel.displayTokenPriceAttributedText

    self.layoutIfNeeded()
  }
}
