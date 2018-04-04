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

  func updateCell(with transaction: KNHistoryTransaction) {
    self.txDateLabel.text = self.dateFormatter.string(from: transaction.date)
    if transaction.to.isEmpty && transaction.fromToken.isEmpty && transaction.toToken.isEmpty {
      // Receive token
      self.txTypeLabel.text = "Receive"
      self.txDetailsLabel.text = transaction.from
    } else if !transaction.fromToken.isEmpty && !transaction.toToken.isEmpty {
      // Exchange token
      // TODO: Fix me
      self.txTypeLabel.text = "Exchange from ETH to KNC"
      self.txDetailsLabel.text = "1 ETH for 370.4333 KNC"
    } else {
      // Transfer
      // TODO: Fix me
      self.txTypeLabel.text = "Transfer token"
      self.txDetailsLabel.text = transaction.to
    }
    self.txAmountLabel.text = EtherNumberFormatter.full.number(from: transaction.value, decimals: 18)?.shortString(decimals: 18)
  }
}
