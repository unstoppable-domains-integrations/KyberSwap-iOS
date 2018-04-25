// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNTransactionCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kTransactionCollectionViewCell"
  static let cellHeight: CGFloat = 80.0

  fileprivate lazy var dateFormatter: DateFormatter = {
    let format = DateFormatter()
    format.dateFormat = "dd MMM yyyy, HH:mm"
    return format
  }()

  @IBOutlet weak var txDateLabel: UILabel!
  @IBOutlet weak var txIconImageView: UIImageView!
  @IBOutlet weak var txTypeLabel: UILabel!
  @IBOutlet weak var txDetailsLabel: UILabel!
  @IBOutlet weak var txAmountLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.rounded(color: .clear, width: 0, radius: 10.0)
    self.txDateLabel.text = ""
    self.txTypeLabel.text = ""
    self.txDetailsLabel.text = ""
    self.txAmountLabel.text = ""
  }

  func updateCell(with transaction: KNHistoryTransaction, tokens: [KNToken]) {
    self.txDateLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: Double(transaction.blockTimestamp)))
    self.txTypeLabel.text = "Exchange"
    self.txIconImageView.image = UIImage(named: "exchange")
    guard
      let from = tokens.first(where: { $0.address.lowercased() == transaction.makerTokenAddress.lowercased() }),
      let to = tokens.first(where: { $0.address.lowercased() == transaction.takerTokenAddress }) else {
      self.txDetailsLabel.text = ""
      self.txAmountLabel.text = ""
      return
    }
    let fromAmount: String = EtherNumberFormatter.short.number(from: transaction.makerTokenAmount, decimals: 0)?.shortString(decimals: from.decimal) ?? "0.00"
    let toAmount: String = EtherNumberFormatter.short.number(from: transaction.takerTokenAmount, decimals: 0)?.shortString(decimals: to.decimal) ?? "0.00"
    self.txDetailsLabel.text = "From \(fromAmount) \(transaction.makerTokenSymbol) to \(toAmount) \(transaction.takerTokenSymbol)"
    self.txAmountLabel.text = "\(fromAmount) \(transaction.makerTokenSymbol)"
  }
}
