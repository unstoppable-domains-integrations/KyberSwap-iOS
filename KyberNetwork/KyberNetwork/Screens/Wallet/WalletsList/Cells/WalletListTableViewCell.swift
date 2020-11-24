//
//  WalletListTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/20/20.
//

import UIKit

enum WalletListTableViewCellEvent {
  case copy(index: Int)
  case remove(index: Int)
  case edit(index: Int)
  case select(index: Int)
}

protocol WalletListTableViewCellDelegate: class {
  func walletListTableViewCell(_ controller: WalletListTableViewCell, run event: WalletListTableViewCellEvent)
}

class WalletListTableViewCell: UITableViewCell {
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var walletAddressLabel: UILabel!
  var index: Int = -1
  var delegate: WalletListTableViewCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  func updateCell(with wallet: KNWalletObject, id: Int) {
    self.index = id
    self.walletNameLabel.text = wallet.name
    self.walletAddressLabel.text = wallet.address.lowercased()
    self.backgroundColor = id % 2 == 0 ? UIColor(red: 10, green: 75, blue: 97) : UIColor(red: 8, green: 66, blue: 85)
    self.layoutIfNeeded()
  }

  @IBAction func editButtonTapped(_ sender: UIButton) {
    self.delegate?.walletListTableViewCell(self, run: .edit(index: self.index))
  }
  
  @IBAction func copyButtonTapped(_ sender: UIButton) {
    self.delegate?.walletListTableViewCell(self, run: .copy(index: self.index))
  }

  @IBAction func deleteButtonTapped(_ sender: UIButton) {
    self.delegate?.walletListTableViewCell(self, run: .remove(index: self.index))
  }
  
  @IBAction func tapCell(_ sender: UIButton) {
    self.delegate?.walletListTableViewCell(self, run: .select(index: self.index))
  }
  
}
