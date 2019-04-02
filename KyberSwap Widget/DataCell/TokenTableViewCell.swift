// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class TokenTableViewCell: UITableViewCell {

  lazy var priceFomatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 9
    formatter.minimumFractionDigits = 0
    return formatter
  }()

  lazy var changeFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
  }()

  @IBOutlet weak var symbolLabel: UILabel!
  @IBOutlet weak var tokenImageView: UIImageView!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var changePercentLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  func updateCell(with data: [String: Any]) {
    let symbol = data["token_symbol"] as? String ?? ""
    let price = data["rate_usd_now"] as? Double ?? 0.0
    let change = data["change_usd_24h"] as? Double ?? 0.0
    self.tokenImageView.image = UIImage(named: symbol.lowercased())
    self.symbolLabel.text = symbol
    self.priceLabel.text = self.priceFomatter.string(from: NSNumber(value: price))
    var changeText = (self.changeFormatter.string(from: NSNumber(value: change)) ?? "") + "%"
    if change == 0 {
      self.changePercentLabel.textColor = UIColor(red: 20, green: 25, blue: 39)
    } else if change > 0 {
      self.changePercentLabel.textColor = UIColor(red: 49, green: 203, blue: 158)
      changeText = "+\(changeText)"
    } else {
      self.changePercentLabel.textColor = UIColor(red: 249, green: 99, blue: 99)
      changeText = "\(changeText)"
    }
    self.changePercentLabel.text = changeText
  }
}
