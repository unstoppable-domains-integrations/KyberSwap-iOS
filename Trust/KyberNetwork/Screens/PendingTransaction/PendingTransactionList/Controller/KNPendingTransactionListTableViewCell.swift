// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNPendingTransactionListTableViewCell: UITableViewCell {

  static let cellHeight: CGFloat = 100.0

  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var toDescriptionLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.rounded(color: .clear, width: 0, radius: 10.0)
  }

  func updateCell(with transaction: Transaction) {
    guard let localObjc = transaction.localizedOperations.first else { return }
    let fromToken = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.address == localObjc.from })!

    self.amountLabel.text = "\(fromToken.symbol) \(transaction.value)"

    if localObjc.type.lowercased() == "exchange" {
      let toToken = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.address == localObjc.to })!
      self.typeLabel.text = "Exchange".toBeLocalised()
      self.toDescriptionLabel.text = "\(toToken.symbol) \(localObjc.value)"
    } else {
      self.typeLabel.text = "Transfer".toBeLocalised()
      self.toDescriptionLabel.text = transaction.to
    }

    let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd MMM yyyy, HH:mm:ss"
      return formatter
    }()
    self.timeLabel.text = dateFormatter.string(from: transaction.date)
    self.layoutIfNeeded()
  }
}
