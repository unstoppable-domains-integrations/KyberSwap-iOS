// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNLimitOrderTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenSymbolLabel: UILabel!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenNameLabel.text = ""
    self.tokenSymbolLabel.text = ""
    self.tokenBalanceLabel.text = ""
  }

  func updateCell(with token: TokenObject, balance: BigInt?) {
    if let image = UIImage(named: token.icon.lowercased()) {
      self.tokenIconImageView.image = image
    } else {
      self.tokenIconImageView.setImage(
        with: token.iconURL,
        placeholder: UIImage(named: "default_token"))
    }
    let isETHStar = (token.isWETH || token.isETH)
    self.tokenSymbolLabel.text = isETHStar ? "ETH*" : "\(token.symbol.prefix(8))"
    self.tokenSymbolLabel.font = isETHStar ? UIFont.Kyber.semiBold(with: 14) : UIFont.Kyber.medium(with: 14)
    self.tokenSymbolLabel.addLetterSpacing()
    self.tokenNameLabel.text = isETHStar ? "Ether that is compatible to ERC20 standard. 1 WETH is equal to 1 ETH. Limit Order works with WETH (not ETH).".toBeLocalised() : token.name
    self.tokenNameLabel.textColor = isETHStar ? UIColor(red: 20, green: 25, blue: 39) : UIColor(red: 158, green: 161, blue: 170)
    self.tokenNameLabel.font = UIFont.Kyber.medium(with: 12, italic: isETHStar)
    self.tokenNameLabel.addLetterSpacing()
    let balText: String = balance?.string(
      decimals: token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(token.decimals, 6)
      ) ?? ""
    self.tokenBalanceLabel.text = "\(balText.prefix(12))"
    self.tokenBalanceLabel.addLetterSpacing()
    self.layoutIfNeeded()
  }
}
