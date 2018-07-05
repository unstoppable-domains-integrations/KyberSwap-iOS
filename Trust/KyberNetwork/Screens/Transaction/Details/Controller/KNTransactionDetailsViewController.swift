// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

enum KNTransactionDetailsViewEvent {
  case back
  case openEtherScan
}

protocol KNTransactionDetailsViewControllerDelegate: class {
  func transactionDetailsViewController(_ controller: KNTransactionDetailsViewController, run event: KNTransactionDetailsViewEvent)
}

class KNTransactionDetailsViewController: KNBaseViewController {

  weak var delegate: KNTransactionDetailsViewControllerDelegate?
  fileprivate var viewModel: KNTransactionDetailsViewModel

  @IBOutlet weak var navigationTitleLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var fromLabel: UILabel!
  @IBOutlet weak var toLabel: UILabel!
  @IBOutlet weak var txHashLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!

  init(viewModel: KNTransactionDetailsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTransactionDetailsViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.updateUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  fileprivate func setupUI() {
    let fromTapGes = UITapGestureRecognizer(target: self, action: #selector(self.fromAddressTapped(_:)))
    self.fromLabel.addGestureRecognizer(fromTapGes)

    let toTapGes = UITapGestureRecognizer(target: self, action: #selector(self.toAddressTapped(_:)))
    self.toLabel.addGestureRecognizer(toTapGes)

    let txHashTapGes = UITapGestureRecognizer(target: self, action: #selector(self.txHashTapped(_:)))
    self.txHashLabel.addGestureRecognizer(txHashTapGes)
  }

  fileprivate func updateUI() {
    self.amountLabel.text = self.viewModel.displayedAmountString
    self.amountLabel.textColor = UIColor(hex: self.viewModel.displayedAmountColorHex)

    self.fromLabel.attributedText = self.viewModel.fromAttributedString()
    self.toLabel.attributedText = self.viewModel.toAttributedString()
    self.txHashLabel.attributedText = self.viewModel.txHashAttributedString()
    self.dateLabel.text = self.viewModel.dateString()

    self.view.updateConstraintsIfNeeded()
    self.view.layoutIfNeeded()
  }

  @objc func fromAddressTapped(_ sender: Any) {
    self.copy(text: self.viewModel.transaction?.from ?? "")
  }

  @objc func toAddressTapped(_ sender: Any) {
    self.copy(text: self.viewModel.transaction?.to ?? "")
  }

  @objc func txHashTapped(_ sender: Any) {
    self.copy(text: self.viewModel.transaction?.id ?? "")
  }

  fileprivate func copy(text: String) {
    UIPasteboard.general.string = text

    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = "Copied".toBeLocalised()
    hud.hide(animated: true, afterDelay: 1.5)
  }

  func coordinator(update transaction: Transaction, currentWallet: KNWalletObject) {
    self.viewModel.update(transaction: transaction, currentWallet: currentWallet)
    self.updateUI()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.transactionDetailsViewController(self, run: .back)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.transactionDetailsViewController(self, run: .back)
    }
  }
}
