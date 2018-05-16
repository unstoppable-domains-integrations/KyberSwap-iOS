// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNExchangeRateCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kExchangeRateCollectionViewCell"
  static let cellHeight: CGFloat = 60.0
  static let cellWidth: CGFloat = 120.0

  @IBOutlet weak var tokenSymbolLabel: UILabel!
  @IBOutlet weak var exchangeRateLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenSymbolLabel.text = ""
    self.exchangeRateLabel.text = ""
  }

  func updateCell(with source: TokenObject, dest: TokenObject?) {
    if let dest = dest {
      // between 2 tokens
      self.tokenSymbolLabel.text = "\(source.symbol)/\(dest.symbol)"
      if let exchangeRate = KNRateCoordinator.shared.getRate(from: source, to: dest) {
        self.exchangeRateLabel.text = EtherNumberFormatter.short.string(from: exchangeRate.rate)
      } else {
        self.exchangeRateLabel.text = "-.-"
      }
    } else {
      //source and USD
      self.tokenSymbolLabel.text = "\(source.symbol)/USD"
      if let exchangeRate = KNRateCoordinator.shared.usdRate(for: source) {
        self.exchangeRateLabel.text = EtherNumberFormatter.short.string(from: exchangeRate.rate)
      } else {
        self.exchangeRateLabel.text = "-.-"
      }
    }
  }
}
