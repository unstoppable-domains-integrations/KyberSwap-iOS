// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KMarketCollectionViewCellModel {
  let token: TokenObject
  let trackerRate: KNTrackerRate?
  let currencyType: KWalletCurrencyType
  let index: Int

  init(
    token: TokenObject,
    trackerRate: KNTrackerRate?,
    currencyType: KWalletCurrencyType,
    index: Int
    ) {
    self.token = token
    self.trackerRate = trackerRate
    self.currencyType = currencyType
    self.index = index
  }

  var backgroundColor: UIColor {
    return self.index % 2 == 0 ? .white : UIColor(red: 246, green: 247, blue: 250)
  }

  var displaySymbolString: String { return self.token.symbol }
  var displayNameString: String { return self.token.name }

  var firstPriceString: String {
    return self.currencyType == .eth ? self.displayETHRateString : self.displayUSDRateString
  }

  var secondPriceString: String {
    return self.currencyType == .usd ? self.displayETHRateString : self.displayUSDRateString
  }

  var displayETHRateString: String {
    guard let trackerRate = self.trackerRate else { return "--- ETH" }
    let rate = KNRate.rateETH(from: trackerRate).rate
    let rateString = rate.string(units: .ether, minFractionDigits: 0, maxFractionDigits: 6).prefix(11)
    return "\(rateString.prefix(11)) ETH"
   }

  var displayUSDRateString: String {
    guard let trackerRate = self.trackerRate else { return "--- USD" }
    let rate = KNRate.rateUSD(from: trackerRate).rate
    let rateString = rate.string(units: .ether, minFractionDigits: 0, maxFractionDigits: 6).prefix(11)
    return "\(rateString.prefix(11)) USD"
   }

  var colorChange24h: UIColor {
    guard let tracker = self.trackerRate else { return UIColor(red: 49, green: 203, blue: 158) }
    let change: Double = {
      if self.currencyType == .eth { return tracker.changeETH24h }
      return tracker.changeUSD24h
     }()
    if change >= 0 { return UIColor(red: 49, green: 203, blue: 158) }
    return UIColor(red: 209, green: 47, blue: 47)
  }

  var change24hString: String {
    guard let tracker = self.trackerRate else { return "---" }
    let change: Double = {
      if self.currencyType == .eth { return tracker.changeETH24h }
      return tracker.changeUSD24h
    }()
    return "\("\(change)".prefix(5))%"
  }
}

class KMarketCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "KMarketCollectionViewCell"
  static let cellHeight: CGFloat = 64

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var symbolLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var firstPriceLabel: UILabel!
  @IBOutlet weak var secondPriceLabel: UILabel!
  @IBOutlet weak var change24hLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.iconImageView.image = nil
    self.symbolLabel.text = ""
    self.nameLabel.text = ""
    self.firstPriceLabel.text = ""
    self.secondPriceLabel.text = ""
    self.change24hLabel.text = ""
    self.iconImageView.rounded(radius: self.iconImageView.frame.width / 2.0)
  }

  func updateCellView(with viewModel: KMarketCollectionViewCellModel) {
    self.iconImageView.setTokenImage(
      token: viewModel.token,
      size: self.iconImageView.frame.size
    )
    self.symbolLabel.text = viewModel.displaySymbolString
    self.nameLabel.text = viewModel.displayNameString
    self.firstPriceLabel.text = viewModel.firstPriceString
    self.secondPriceLabel.text = viewModel.secondPriceString
    self.change24hLabel.text = viewModel.change24hString
    self.change24hLabel.textColor = viewModel.colorChange24h
    self.backgroundColor = viewModel.backgroundColor
  }
}
