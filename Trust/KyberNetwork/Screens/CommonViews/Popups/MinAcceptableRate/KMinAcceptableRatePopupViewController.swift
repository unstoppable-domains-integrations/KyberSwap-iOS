// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KMinAcceptableRatePopupViewModel {
  let minRate: String
  let symbol: String

  var titleAttributes: [NSAttributedStringKey: Any] {
    return [
      NSAttributedStringKey.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
    ]
  }

  var descAttributes: [NSAttributedStringKey: Any] {
    return [
      NSAttributedStringKey.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    ]
  }

  var highlightedAttributes: [NSAttributedStringKey: Any] {
    return [
      NSAttributedStringKey.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedStringKey.font: UIFont.Kyber.bold(with: 14),
    ]
  }

  init(minRate: String, symbol: String) {
    self.minRate = minRate
    self.symbol = symbol
  }

  var attributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "Min Acceptable Rate".toBeLocalised(), attributes: self.titleAttributes))
    attributedString.append(NSAttributedString(string: "\n\nGuard yourself during volatile times by setting the lowest conversion rate you would accept for this transaction.\n".toBeLocalised(), attributes: self.descAttributes))
    attributedString.append(NSAttributedString(string: "Setting a high value may result in a failed transaction and you would be charged gas fees.\n\n", attributes: self.descAttributes))
    attributedString.append(NSAttributedString(string: "Our recommended                                           Min Acceptable Rate is ".toBeLocalised(), attributes: self.descAttributes))
    attributedString.append(NSAttributedString(string: minRate, attributes: self.highlightedAttributes))
    attributedString.append(NSAttributedString(string: " \(symbol)", attributes: self.descAttributes))
    return attributedString
  }
}

class KMinAcceptableRatePopupViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var desciptionLabel: UILabel!
  let viewModel: KMinAcceptableRatePopupViewModel

  init(viewModel: KMinAcceptableRatePopupViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KMinAcceptableRatePopupViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.desciptionLabel.attributedText = self.viewModel.attributedString
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    if sender.location(in: self.view).y <= self.containerView.frame.minY {
      self.dismiss(animated: true, completion: nil)
    }
  }
}
