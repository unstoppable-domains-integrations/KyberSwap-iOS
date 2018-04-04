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
    self.txDateLabel.text = self.dateFormatter.string(from: transaction.date)
    if transaction.to.isEmpty && transaction.fromToken.isEmpty && transaction.toToken.isEmpty {
      self.txIconImageView.image = UIImage(named: "transaction_received")
      // Receive token
      self.txTypeLabel.text = "Receive"
      self.txDetailsLabel.text = transaction.from
    } else if !transaction.fromToken.isEmpty && !transaction.toToken.isEmpty {
      // Exchange token
      // TODO: Fix me
      let fromToken = tokens.first(where: { $0.address == transaction.fromToken })
      let toToken = tokens.first(where: { $0.address == transaction.toToken })
      self.txTypeLabel.text = "Exchange from \(fromToken?.symbol ?? "token") to \(toToken?.symbol ?? "token"))"
      self.txDetailsLabel.text = "1 \(fromToken?.symbol ?? "token") for 370.4333 \(toToken?.symbol ?? "token")"
      self.txAmountLabel.text = (EtherNumberFormatter.full.number(from: transaction.value, decimals: 0))?.shortString(decimals: fromToken?.decimal ?? 18)
      self.txIconImageView.image = UIImage(named: "exchange")
    } else {
      // Transfer
      // TODO: Fix me
      let fromToken = tokens.first(where: { $0.address == transaction.fromToken })
      self.txTypeLabel.text = "Transfer \(fromToken?.symbol ?? "token")"
      self.txDetailsLabel.text = transaction.to
      self.txAmountLabel.text = (EtherNumberFormatter.full.number(from: transaction.value, decimals: 0))?.shortString(decimals: fromToken?.decimal ?? 18)
      self.txIconImageView.image = UIImage(named: "transaction_sent")
    }
  }
}
