// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNPendingTransactionListTableViewCell: UITableViewCell {

  static let cellHeight: CGFloat = 120.0

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
    if let fromToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.contract == localObjc.from }) {
      self.amountLabel.text = "\(fromToken.symbol) \(transaction.value)"
    }

    if localObjc.type.lowercased() == "exchange" {
      self.typeLabel.text = "Exchange".toBeLocalised()
      if let toToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.contract == localObjc.to }) {
        self.toDescriptionLabel.text = "\(toToken.symbol) \(localObjc.value)"
      }
      self.toDescriptionLabel.font = self.toDescriptionLabel.font.withSize(16)
    } else {
      self.typeLabel.text = "Transfer".toBeLocalised()
      self.toDescriptionLabel.text = transaction.to
      self.toDescriptionLabel.font = self.toDescriptionLabel.font.withSize(12)
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
