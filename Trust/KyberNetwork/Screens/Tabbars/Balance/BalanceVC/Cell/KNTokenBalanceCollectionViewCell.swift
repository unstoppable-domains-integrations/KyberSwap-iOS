// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KNTokenBalanceCollectionViewCellModel {

  fileprivate let highlighted: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayDark,
    NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 16)!,
  ]
  fileprivate let normal: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor.Kyber.grey,
    NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 12)!,
  ]

  let token: TokenObject
  let icon: String?
  let trackerRate: KNTrackerRate?
  let balance: Balance?

  var displayedType: KNBalanceDisplayDataType = .eth

  init(
    token: TokenObject,
    icon: String?,
    trackerRate: KNTrackerRate?,
    balance: Balance?,
    displayedType: KNBalanceDisplayDataType
    ) {
    self.token = token
    self.icon = icon
    self.trackerRate = trackerRate
    self.balance = balance
    self.displayedType = displayedType
  }

  fileprivate var displayBalanceHoldingsText: String {
    if let amount = balance?.value.string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: 6) {
      return "Bal \(amount.prefix(11))"
    }
    return "Bal ---"
  }

  fileprivate var displayBalanceInUSD: String {
    if let amount = balance?.value, let trackerRate = self.trackerRate {
      let rate = KNRate.rateUSD(from: trackerRate)
      let value = (amount * rate.rate / BigInt(10).power(self.token.decimals)).string(units: .ether, minFractionDigits: 0, maxFractionDigits: 6)
      return "Val $\(value.prefix(11))"
    }
    return "Val ---"
  }

  fileprivate var displayBalanceInETH: String {
    if let amount = balance?.value, let trackerRate = self.trackerRate {
      let rate = KNRate.rateETH(from: trackerRate)
      let value = (amount * rate.rate / BigInt(10).power(self.token.decimals)).string(units: .ether, minFractionDigits: 0, maxFractionDigits: 9)
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
        if let trackerRate = self.trackerRate {
          return KNRate.rateUSD(from: trackerRate).rate
        }
        return nil
      }
      if let trackerRate = self.trackerRate {
        return KNRate.rateETH(from: trackerRate).rate
      }
      return nil
    }()
    let maxFractionsDigits: Int = self.displayedType == .eth ? 9 : 6
    let attributedString = NSMutableAttributedString()
    let rateString = rate?.string(units: .ether, minFractionDigits: 0, maxFractionDigits: maxFractionsDigits) ?? "-.--"
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
    let change24h = self.displayedType == .eth ? self.trackerRate?.changeETH24h : self.trackerRate?.changeUSD24h
    if let percentageChange = change24h {
      return "\("\(percentageChange)".prefix(5))%"
    }
    return "- - - - - -"
  }

  var textColorChange24h: UIColor {
    let change24h = self.displayedType == .eth ? self.trackerRate?.changeETH24h : self.trackerRate?.changeUSD24h
    if let percentageChange = change24h {
      return percentageChange < 0 ? UIColor.Kyber.orange : UIColor.Kyber.green
    }
    return UIColor.Kyber.gray
  }

  var backgroundColorChange24h: UIColor {
    let change24h = self.displayedType == .eth ? self.trackerRate?.changeETH24h : self.trackerRate?.changeUSD24h
    if let percentageChange = change24h {
      return percentageChange < 0 ? UIColor.Kyber.veryLightOrange : UIColor.Kyber.veryLightGreen
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
