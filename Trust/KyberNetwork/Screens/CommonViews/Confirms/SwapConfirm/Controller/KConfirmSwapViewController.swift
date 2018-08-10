// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KConfirmSwapViewControllerDelegate: class {
  func kConfirmSwapViewController(_ controller: KConfirmSwapViewController, run event: KConfirmViewEvent)
}

class KConfirmSwapViewController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var fromAmountLabel: UILabel!
  @IBOutlet weak var toAmountLabel: UILabel!

  @IBOutlet weak var firstSeparatorView: UIView!

  @IBOutlet weak var expectedRateLabel: UILabel!
  @IBOutlet weak var minAcceptableRateLabel: UILabel!

  @IBOutlet weak var secondSeparatorView: UIView!

  @IBOutlet weak var transactionFeeETHLabel: UILabel!
  @IBOutlet weak var transactionFeeUSDLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  fileprivate var viewModel: KConfirmSwapViewModel
  weak var delegate: KConfirmSwapViewControllerDelegate?

  init(viewModel: KConfirmSwapViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KConfirmSwapViewController.className, bundle: nil)
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

    self.fromAmountLabel.text = self.viewModel.leftAmountString
    self.toAmountLabel.text = self.viewModel.rightAmountString

    self.firstSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.expectedRateLabel.text = self.viewModel.displayEstimatedRate
    self.minAcceptableRateLabel.text = self.viewModel.minRateString

    self.transactionFeeETHLabel.text = self.viewModel.feeETHString
    self.transactionFeeUSDLabel.text = self.viewModel.feeUSDString

    self.secondSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.confirmButton.rounded(radius: self.confirmButton.frame.height / 2.0)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kConfirmSwapViewController(self, run: .cancel)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended { self.delegate?.kConfirmSwapViewController(self, run: .cancel) }
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    let event = KConfirmViewEvent.confirm(type: KNTransactionType.exchange(self.viewModel.transaction))
    self.delegate?.kConfirmSwapViewController(self, run: event)
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.delegate?.kConfirmSwapViewController(self, run: .cancel)
  }
}
