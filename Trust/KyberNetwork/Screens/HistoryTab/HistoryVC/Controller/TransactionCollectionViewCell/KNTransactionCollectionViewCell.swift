// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNTransactionCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kTransactionCollectionViewCell"
  static let cellHeight: CGFloat = 80.0

  fileprivate lazy var dateFormatter: DateFormatter = {
    let format = DateFormatter()
    format.dateFormat = "HH:mm"
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

  func updateCell(with transaction: KNHistoryTransaction, tokens: [TokenObject], ownerAddress: String) {
    self.txDateLabel.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: Double(transaction.blockTimestamp)))
    self.txTypeLabel.text = "Exchanged"
    self.txIconImageView.image = UIImage(named: "exchange")
    guard
      let from = tokens.first(where: { $0.contract.lowercased() == transaction.makerTokenAddress.lowercased() }),
      let to = tokens.first(where: { $0.contract.lowercased() == transaction.takerTokenAddress }) else {
      self.txDetailsLabel.text = ""
      self.txAmountLabel.text = ""
      return
    }
    let fromAmount: String = EtherNumberFormatter.short.number(from: transaction.makerTokenAmount, decimals: 0)?.shortString(decimals: from.decimals) ?? "0.00"
    let toAmount: String = EtherNumberFormatter.short.number(from: transaction.takerTokenAmount, decimals: 0)?.shortString(decimals: to.decimals) ?? "0.00"
    self.txDetailsLabel.text = "Convert \(fromAmount) \(transaction.makerTokenSymbol) to \(toAmount) \(transaction.takerTokenSymbol)"

    let amountSign = transaction.makerAddress == ownerAddress ? "-" : "+"
    let amountColor = transaction.makerAddress == ownerAddress ? UIColor.Kyber.red : UIColor.Kyber.green

    self.txAmountLabel.text = "\(amountSign)\(fromAmount) \(transaction.makerTokenSymbol)"
    self.txAmountLabel.textColor = amountColor
  }

  func updateCell(with pending: Transaction, tokens: [TokenObject], ownerAddress: String) {
    self.txDateLabel.text = self.dateFormatter.string(from: pending.date)
    guard let localObject = pending.localizedOperations.first else { return }
    if localObject.type == "exchange" {
      // trade/exchange transaction
      self.txTypeLabel.text = "Exchange"
      self.txIconImageView.image = UIImage(named: "exchange")
      let fromAmount: String = String(pending.value.prefix(8))
      let toAmount: String = String(localObject.value.prefix(8))
      self.txDetailsLabel.text = "Convert \(fromAmount) \(localObject.symbol ?? "") to \(toAmount) \(localObject.name ?? "")"
      self.txAmountLabel.text = "+ \(localObject.value.prefix(8)) \(localObject.name ?? "")"
      self.txAmountLabel.textColor = UIColor.Kyber.green
    } else {
      // normal transfer transaction
      self.txTypeLabel.text = "Send"
      self.txIconImageView.image = UIImage(named: "transaction_sent")
      self.txDetailsLabel.text = pending.to
      self.txAmountLabel.text = "- \(pending.value.prefix(8)) \(localObject.symbol ?? "")"
      self.txAmountLabel.textColor = UIColor.Kyber.red
    }
  }

  func updateCell(with transaction: KNTokenTransaction, ownerAddress: String) {
    let isSent: Bool = ownerAddress.lowercased() == transaction.from.lowercased()
    self.txDateLabel.text = self.dateFormatter.string(from: transaction.date)
    self.txTypeLabel.text = {
      return isSent ? "Sent" : "Received"
    }()
    self.txIconImageView.image = {
      return isSent ? UIImage(named: "transaction_sent") : UIImage(named: "transaction_received")
    }()
    self.txDetailsLabel.text = "\(transaction.to.prefix(10))....\(transaction.to.suffix(10))"
    let amountString: String = {
      let number = EtherNumberFormatter.short.number(from: transaction.value, decimals: 0)
      let amount: String = number?.shortString(decimals: Int(transaction.tokenDecimal) ?? 0) ?? "0.0"
      let sign: String = isSent ? "-" : "+"
      return sign + amount
    }()
    self.txAmountLabel.text = "\(amountString) \(transaction.tokenSymbol)"
    self.txAmountLabel.textColor = {
      return isSent ? UIColor.Kyber.red : UIColor.Kyber.green
    }()
  }
}
