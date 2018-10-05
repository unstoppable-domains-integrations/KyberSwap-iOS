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

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navigationTitleLabel: UILabel!
  @IBOutlet weak var txStatusLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var fromLabel: UILabel!
  @IBOutlet weak var toLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var txHashLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var dateTextLabel: UILabel!
  @IBOutlet weak var viewOnEtherscanButton: UIButton!

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
    self.fromTextLabel.text = NSLocalizedString("from", value: "From", comment: "")
    self.toTextLabel.text = NSLocalizedString("to", value: "To", comment: "")
    self.dateTextLabel.text = NSLocalizedString("date", value: "Date", comment: "")
    self.navigationTitleLabel.text = NSLocalizedString("transaction.details", value: "Transaction Details", comment: "")
    self.headerContainerView.backgroundColor = KNAppStyleType.current.walletFlowHeaderColor
    self.txStatusLabel.rounded(radius: 4.0)
    let fromTapGes = UITapGestureRecognizer(target: self, action: #selector(self.fromAddressTapped(_:)))
    self.fromLabel.addGestureRecognizer(fromTapGes)

    let toTapGes = UITapGestureRecognizer(target: self, action: #selector(self.toAddressTapped(_:)))
    self.toLabel.addGestureRecognizer(toTapGes)

    let txHashTapGes = UITapGestureRecognizer(target: self, action: #selector(self.txHashTapped(_:)))
    self.txHashLabel.addGestureRecognizer(txHashTapGes)
    self.viewOnEtherscanButton.rounded(radius: 5.0)
    self.viewOnEtherscanButton.setTitle(
      NSLocalizedString("view.on.etherscan", value: "View on Etherscan", comment: ""),
      for: .normal
    )
  }

  fileprivate func updateUI() {
    if let state = self.viewModel.transaction?.state {
      self.txStatusLabel.isHidden = false
      switch state {
      case .completed:
        self.txStatusLabel.text = "\(NSLocalizedString("success", value: "Success", comment: ""))  "
        self.txStatusLabel.backgroundColor = UIColor.Kyber.shamrock
      case .failed, .error:
        self.txStatusLabel.text = "\(NSLocalizedString("failed", value: "Failed", comment: ""))  "
        self.txStatusLabel.backgroundColor = UIColor.Kyber.strawberry
      case .pending:
        self.txStatusLabel.text = "\(NSLocalizedString("pending", value: "Pending", comment: ""))  "
        self.txStatusLabel.backgroundColor = UIColor.Kyber.merigold
      default: break
      }
    } else {
      self.txStatusLabel.isHidden = true
    }

    self.amountLabel.text = self.viewModel.displayedAmountString
    self.amountLabel.textColor = self.viewModel.displayedAmountColor

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
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
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

  @IBAction func viewOnEtherscanButtonPressed(_ sender: Any) {
    self.delegate?.transactionDetailsViewController(self, run: .openEtherScan)
  }
}
