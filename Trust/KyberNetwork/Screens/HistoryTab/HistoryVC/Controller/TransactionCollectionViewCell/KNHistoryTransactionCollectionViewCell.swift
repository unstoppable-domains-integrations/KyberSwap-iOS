// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNHistoryTransactionCollectionViewCellDelegate: class {
  func historyTransactionCollectionViewCell(_ cell: KNHistoryTransactionCollectionViewCell, openDetails transaction: Transaction)
}

class KNHistoryTransactionCollectionViewModel {
  let transaction: Transaction
  let ownerAddress: String

  init(
    transaction: Transaction,
    ownerAddress: String
    ) {
    self.transaction = transaction
    self.ownerAddress = ownerAddress
  }

  var leftLabelString: String {
    guard let localObject = self.transaction.localizedOperations.first else { return "" }
    if localObject.type == "exchange" {
      // trade/exchange transaction
      let fromAmount: String = String(self.transaction.value.prefix(6))
      return "\(fromAmount) \(localObject.symbol ?? "")"
    } else {
      // normal transfer transaction
      return "\(self.transaction.value.prefix(6)) \(localObject.symbol ?? "")"
    }
  }

  var rightLabelString: String {
    guard let localObject = self.transaction.localizedOperations.first else { return "" }
    if localObject.type == "exchange" {
      // trade/exchange transaction
      let toAmount: String = String(localObject.value.prefix(6))
      return "\(toAmount) \(localObject.name ?? "")"
    } else {
      // normal transfer transaction
      if let contact = KNContactStorage.shared.get(forPrimaryKey: self.transaction.to.lowercased()) {
        return contact.name
      }
      return "\(self.transaction.to.prefix(6))...\(self.transaction.to.suffix(1))"
    }
  }
}

class KNHistoryTransactionCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kHistoryTransactionCellID"
  static let height: CGFloat = 36.0

  weak var delegate: KNHistoryTransactionCollectionViewCellDelegate?
  fileprivate var viewModel: KNHistoryTransactionCollectionViewModel!

  @IBOutlet weak var fromLabel: UILabel!
  @IBOutlet weak var toLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func updateCell(with model: KNHistoryTransactionCollectionViewModel) {
    self.viewModel = model
    self.fromLabel.text = model.leftLabelString
    self.toLabel.text = model.rightLabelString
    self.layoutIfNeeded()
  }

  @IBAction func linkButtonPressed(_ sender: Any) {
    self.delegate?.historyTransactionCollectionViewCell(self, openDetails: self.viewModel.transaction)
  }
}
