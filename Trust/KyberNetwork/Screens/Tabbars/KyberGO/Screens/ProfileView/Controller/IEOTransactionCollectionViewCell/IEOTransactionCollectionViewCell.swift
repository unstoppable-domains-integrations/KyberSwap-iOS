// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct IEOTransactionCollectionViewModel {
  let transaction: IEOTransaction
  let ieoObject: IEOObject?

  init(transaction: IEOTransaction, ieoObject: IEOObject?) {
    self.transaction = transaction
    self.ieoObject = ieoObject
  }

  var iconImageName: String {
    if transaction.txStatus == .fail || transaction.txStatus == .lost {
      return "error_icon"
    }
    return "token_swap_icon"
  }

  var statusLabelText: String {
    return transaction.txStatus.displayText
  }

  let normalTextAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor.Kyber.grey,
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
  ]

  let highlightedTextAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor.Kyber.gray,
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
  ]

  var detailsLabelText: NSAttributedString {
    guard let ieo = self.ieoObject else {
      return NSAttributedString(
        string: "Unknown token sale".toBeLocalised(),
        attributes: normalTextAttributes
      )
    }
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "Buy \(ieo.name)", attributes: highlightedTextAttributes))
    attributedString.append(NSAttributedString(string: "\nFrom: \(transaction.srcAddress.prefix(8))....\(transaction.srcAddress.suffix(6))", attributes: normalTextAttributes))
    return attributedString
  }

  var amountLabelText: String {
    guard let ieo = self.ieoObject else {
      return "Unknown token sale".toBeLocalised()
    }

    if self.transaction.txStatus == .pending {
      return ""
    }

    if self.transaction.txStatus != .success {
      return "0 \(ieo.tokenSymbol)"
    }

    //let fromText: String = "\(transaction.sentETH) ETH"
    let toText: String = {
      let distributedAmount: BigInt = BigInt(transaction.distributedTokensWei)
      return distributedAmount.string(
        decimals: ieo.tokenDecimals,
        minFractionDigits: 0,
        maxFractionDigits: 4
      )
    }()
    //return "\(fromText) -> \(toText)"
    return "+\(toText) \(ieo.tokenSymbol)"
  }

  var amountLabelTextColor: UIColor {
    return self.transaction.txStatus == .pending ? UIColor.Kyber.orange : UIColor.Kyber.green
  }

  var backgroundColor: UIColor {
    if transaction.txStatus == .pending { return UIColor.Kyber.veryLightOrange }
    return transaction.viewed ? .white : UIColor.Kyber.veryLightGreen
  }
}

class IEOTransactionCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kIEOTransactionCollectionViewCellID"
  static let height: CGFloat = 84.0

  @IBOutlet weak var txStatusLabel: UILabel!
  @IBOutlet weak var txDetailsLabel: UILabel!
  @IBOutlet weak var txAmountLabel: UILabel!
  @IBOutlet weak var txIconImageView: UIImageView!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func updateCell(with viewModel: IEOTransactionCollectionViewModel) {
    self.txIconImageView.image = UIImage(named: viewModel.iconImageName)
    self.txStatusLabel.text = viewModel.statusLabelText
    self.txDetailsLabel.attributedText = viewModel.detailsLabelText
    self.txAmountLabel.text = viewModel.amountLabelText
    self.backgroundColor = viewModel.backgroundColor
  }
}
