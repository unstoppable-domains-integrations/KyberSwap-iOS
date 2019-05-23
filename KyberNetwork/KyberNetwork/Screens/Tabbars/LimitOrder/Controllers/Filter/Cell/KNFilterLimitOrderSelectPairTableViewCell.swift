// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNFilterLimitOrderSelectPairTableViewCellDelegate: class {
  func filterLimitOrderSelectPairTableViewCell(_ cell: KNFilterLimitOrderSelectPairTableViewCell, didSelect pair: String)
}

class KNFilterLimitOrderSelectPairTableViewCell: UITableViewCell {

  @IBOutlet weak var firstPairSelectButton: UIButton!
  @IBOutlet weak var firstPairLabel: UIButton!
  @IBOutlet weak var secondPairSelectButton: UIButton!
  @IBOutlet weak var secondPairLabel: UIButton!

  fileprivate var firstPair: String = ""
  fileprivate var secondPair: String = ""
  fileprivate var isFirstPairSelected: Bool = false
  fileprivate var isSecondPairSelected: Bool = false

  weak var delegate: KNFilterLimitOrderSelectPairTableViewCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.backgroundColor = .clear
  }

  func updateCell(firstPair: String, isFirstPairSelected: Bool, secondPair: String, isSecondPairSelected: Bool) {
    self.firstPair = firstPair
    self.secondPair = secondPair
    self.isFirstPairSelected = isFirstPairSelected
    self.isSecondPairSelected = isSecondPairSelected

    self.firstPairLabel.setTitle(firstPair, for: .normal)
    self.updateFirstPair(isFirstPairSelected: isFirstPairSelected)
    if secondPair.isEmpty {
      self.secondPairLabel.isHidden = true
      self.secondPairSelectButton.isHidden = true
    } else {
      self.secondPairLabel.isHidden = false
      self.secondPairSelectButton.isHidden = false
      self.secondPairLabel.setTitle(secondPair, for: .normal)
      self.updateSecondPair(isSecondPairSelected: isSecondPairSelected)
    }
  }

  fileprivate func updateFirstPair(isFirstPairSelected: Bool) {
    self.firstPairSelectButton.rounded(
      color: isFirstPairSelected ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.firstPairSelectButton.setImage(
      isFirstPairSelected ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
  }

  fileprivate func updateSecondPair(isSecondPairSelected: Bool) {
    self.secondPairSelectButton.rounded(
      color: isSecondPairSelected ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.secondPairSelectButton.setImage(
      isSecondPairSelected ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
  }

  @IBAction func firstPairSelectButtonPressed(_ sender: Any) {
    self.isFirstPairSelected = !self.isFirstPairSelected
    self.updateFirstPair(isFirstPairSelected: self.isFirstPairSelected)
    self.delegate?.filterLimitOrderSelectPairTableViewCell(self, didSelect: self.firstPair)
    self.layoutIfNeeded()
  }

  @IBAction func secondPairSelectButtonPressed(_ sender: Any) {
    self.isSecondPairSelected = !self.isSecondPairSelected
    self.updateSecondPair(isSecondPairSelected: self.isSecondPairSelected)
    self.delegate?.filterLimitOrderSelectPairTableViewCell(self, didSelect: self.secondPair)
    self.layoutIfNeeded()
  }
}
