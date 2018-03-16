// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNConfirmTransactionViewControllerDelegate: class {
  func confirmTransactionDidConfirm(type: KNTransactionType)
  func confirmTransactionDidBack()
}

class KNConfirmTransactionViewController: KNBaseViewController {

  fileprivate let confirmTransactionCellID = "confirmTransactionCellID"
  fileprivate var transactionType: KNTransactionType
  fileprivate var expectedRate: BigInt?

  @IBOutlet weak var contentTableView: UITableView!
  @IBOutlet weak var confirmButton: UIButton!

  fileprivate var data: [(String, String)] = []

  fileprivate weak var delegate: KNConfirmTransactionViewControllerDelegate?

  init(delegate: KNConfirmTransactionViewControllerDelegate?, type: KNTransactionType, expectedRate: BigInt? = .none) {
    self.delegate = delegate
    self.transactionType = type
    self.expectedRate = expectedRate
    super.init(nibName: KNConfirmTransactionViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(self.backButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = .white
    self.createData()
  }

  fileprivate func setupUI() {

    self.confirmButton.setTitle("Confirm".uppercased().toBeLocalised(), for: .normal)
    self.confirmButton.rounded(color: .clear, width: 0, radius: 5.0)

    let nib = UINib(nibName: KNTransactionDetailsTableViewCell.className, bundle: nil)
    self.contentTableView.register(nib, forCellReuseIdentifier: confirmTransactionCellID)
    self.contentTableView.rowHeight = 60
    self.contentTableView.dataSource = self
    self.contentTableView.delegate = self
  }

  fileprivate func createData() {
    switch self.transactionType {
    case .exchange(let trans):
      let amountSpent = "\(trans.from.symbol)\(trans.amount.fullString(decimals: trans.from.decimal))"
      let usdRate = KNRateCoordinator.shared.usdRates.first(where: { $0.source == trans.from.symbol })?.rate ?? BigInt(0)
      let usdValue = (usdRate * trans.amount).shortString(units: .ether)
      let expectedAmount = trans.amount * (self.expectedRate ?? BigInt(0)) / BigInt(10).power(trans.to.decimal)
      let expectedReceive = "\(trans.to.symbol)\(expectedAmount.fullString(decimals: trans.to.decimal))"
      let rate = "Rate: \(trans.to.symbol)\((self.expectedRate ?? BigInt(0)).shortString(decimals: trans.to.decimal))"
      let minRate = trans.minRate?.shortString(decimals: trans.to.decimal) ?? "--"
      let transFee = (trans.gasPrice ?? KNGasConfiguration.gasPriceDefault) * (trans.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault)
      let fee = transFee.fullString(units: UnitConfiguration.gasFeeUnit)
      self.data = [
        ("Amount Sent", "\(amountSpent)\n$\(usdValue)"),
        ("Expected Receive", "\(expectedReceive)\n\(rate)"),
        ("Min Rate", "\(trans.to.symbol)\(minRate)"),
        ("Est. Fee", "ETH\(fee)"),
      ]
    case .transfer:
        return
    }
    self.contentTableView.reloadData()
  }

  @objc func backButtonPressed(_ sender: Any) {
    self.delegate?.confirmTransactionDidBack()
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    self.delegate?.confirmTransactionDidConfirm(type: self.transactionType)
  }
}

extension KNConfirmTransactionViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }
}

extension KNConfirmTransactionViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.data.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: confirmTransactionCellID, for: indexPath) as! KNTransactionDetailsTableViewCell
    let (field, value) = self.data[indexPath.row]
    cell.updateCell(text: field, details: value)
    return cell
  }
}
