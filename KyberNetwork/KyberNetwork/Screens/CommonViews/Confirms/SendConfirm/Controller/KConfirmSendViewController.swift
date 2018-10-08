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

  @IBOutlet weak var headerContainerView: UIView!
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

  @IBOutlet weak var amountToSendTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!

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

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.firstSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.secondSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  fileprivate func setupUI() {
    let style = KNAppStyleType.current
    self.headerContainerView.backgroundColor = style.walletFlowHeaderColor
    self.titleLabel.text = self.viewModel.titleString

    self.contactImageView.rounded(radius: self.contactImageView.frame.height / 2.0)
    self.contactImageView.image = self.viewModel.addressToIcon

    self.contactNameLabel.text = self.viewModel.contactName
    self.sendAddressLabel.text = self.viewModel.address

    self.sendAmountLabel.text = self.viewModel.totalAmountString
    self.sendAmountUSDLabel.text = self.viewModel.usdValueString

    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString

    self.confirmButton.rounded(radius: style.buttonRadius(for: self.confirmButton.frame.height))
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.confirmButton.backgroundColor = style.walletFlowHeaderColor
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )

    self.firstSeparatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
    self.secondSeparatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)

    self.amountToSendTextLabel.text = NSLocalizedString("amount.to.send", value: "Amount To Send", comment: "").uppercased()
    self.transactionFeeTextLabel.text = NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    let event = KConfirmViewEvent.confirm(type: KNTransactionType.transfer(self.viewModel.transaction))
    self.updateActionButtonsSendingTransfer()
    self.delegate?.kConfirmSendViewController(self, run: event)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kConfirmSendViewController(self, run: .cancel)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.kConfirmSendViewController(self, run: .cancel)
    }
  }

  func updateActionButtonsSendingTransfer() {
    self.confirmButton.backgroundColor = UIColor.clear
    self.confirmButton.setTitle("\(NSLocalizedString("in.progress", value: "In Progress", comment: "")) ...", for: .normal)
    self.confirmButton.setTitleColor(
      KNAppStyleType.current.walletFlowHeaderColor,
      for: .normal
    )
    self.confirmButton.isEnabled = false
    self.cancelButton.isHidden = true
  }

  func resetActionButtons() {
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.confirmButton.setTitleColor(UIColor.white, for: .normal)
    self.confirmButton.backgroundColor = KNAppStyleType.current.walletFlowHeaderColor
    self.confirmButton.isEnabled = true
    self.cancelButton.isHidden = false
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )
  }
}
