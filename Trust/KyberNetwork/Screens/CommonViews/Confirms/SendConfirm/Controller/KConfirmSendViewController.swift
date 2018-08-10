// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KConfirmViewEvent {
  case confirm(type: KNTransactionType)
  case cancel
}

protocol KConfirmSendViewControllerDelegate: class {
  func kConfirmSendViewController(_ controller: KConfirmSendViewController, run event: KConfirmViewEvent)
}

class KConfirmSendViewController: KNBaseViewController {

  @IBOutlet weak var titleLabel: UILabel!

  @IBOutlet weak var contactImageView: UIImageView!
  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var sendAddressLabel: UILabel!

  @IBOutlet weak var firstSeparatorView: UIView!
  @IBOutlet weak var secondSeparatorView: UIView!

  @IBOutlet weak var sendAmountLabel: UILabel!
  @IBOutlet weak var sendAmountUSDLabel: UILabel!

  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  fileprivate let viewModel: KConfirmSendViewModel
  weak var delegate: KConfirmSendViewControllerDelegate?

  init(viewModel: KConfirmSendViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KConfirmSendViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.titleLabel.text = self.viewModel.titleString

    self.contactImageView.rounded(radius: self.contactImageView.frame.height / 2.0)
    self.contactImageView.image = self.viewModel.addressToIcon

    self.contactNameLabel.text = self.viewModel.contactName
    self.sendAddressLabel.text = self.viewModel.address

    self.sendAmountLabel.text = self.viewModel.totalAmountString
    self.sendAmountUSDLabel.text = self.viewModel.usdValueString

    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString

    self.confirmButton.rounded(radius: self.confirmButton.frame.height / 2.0)

    self.firstSeparatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
    self.secondSeparatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    let event = KConfirmViewEvent.confirm(type: KNTransactionType.transfer(self.viewModel.transaction))
    self.delegate?.kConfirmSendViewController(self, run: event)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kConfirmSendViewController(self, run: .cancel)
  }
}
