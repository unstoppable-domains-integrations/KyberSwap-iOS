// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNPendingTransactionListViewControllerDelegate: class {
  func pendingTransactionListViewDidClose()
  func pendingTransactionListViewDidClickExchangeNow()
  func pendingTransactionListViewDidClickTransferNow()
  func pendingTransactionListViewDidSelectTransaction(_ transaction: Transaction)
}

class KNPendingTransactionListViewController: UIViewController {

  fileprivate let transactionListCellID = "transactionListCellID"
  fileprivate let noPendingTransactionViewHeight: CGFloat = 200
  fileprivate let pendingTransactionListMaxHeight: CGFloat = UIScreen.main.bounds.height * 2.0 / 3.0

  fileprivate weak var delegate: KNPendingTransactionListViewControllerDelegate?
  fileprivate var pendingTransactions: [Transaction] = []

  @IBOutlet weak var pendingTransactionListView: UIView!
  @IBOutlet weak var pendingTransactionLabel: UILabel!
  @IBOutlet weak var exchangeNowButton: UIButton!
  @IBOutlet weak var transferNowButton: UIButton!

  @IBOutlet weak var transactionTableView: UITableView!

  @IBOutlet weak var heightContraintForPendingTransactionListView: NSLayoutConstraint!

  init(delegate: KNPendingTransactionListViewControllerDelegate?, pendingTransactions: [Transaction]) {
    self.delegate = delegate
    self.pendingTransactions = pendingTransactions
    super.init(nibName: KNPendingTransactionListViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {

    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

    self.pendingTransactionListView.rounded(color: .clear, width: 0, radius: 10.0)

    self.exchangeNowButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.exchangeNowButton.setTitle("Exchange Now".toBeLocalised(), for: .normal)

    self.transferNowButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.transferNowButton.setTitle("Transfer Now".toBeLocalised(), for: .normal)

    let nib = UINib(nibName: KNPendingTransactionListTableViewCell.className, bundle: nil)
    self.transactionTableView.register(nib, forCellReuseIdentifier: transactionListCellID)
    self.transactionTableView.rowHeight = KNPendingTransactionListTableViewCell.cellHeight
    self.transactionTableView.delegate = self
    self.transactionTableView.dataSource = self
  }

  fileprivate func updateUI() {
    if self.pendingTransactions.isEmpty {
      self.pendingTransactionLabel.text = "You don't have any pending transactions".toBeLocalised()
      self.exchangeNowButton.isHidden = false
      self.transferNowButton.isHidden = false
      self.transactionTableView.isHidden = true
      self.heightContraintForPendingTransactionListView.constant = noPendingTransactionViewHeight
    } else {
      self.pendingTransactionLabel.text = "Your pending transaction(s)".toBeLocalised()
      self.exchangeNowButton.isHidden = true
      self.transferNowButton.isHidden = true
      self.transactionTableView.isHidden = false
      let viewHeight: CGFloat = {
        let tableViewHeight: CGFloat = KNPendingTransactionListTableViewCell.cellHeight * CGFloat(self.pendingTransactions.count)
        return min(tableViewHeight + 200, pendingTransactionListMaxHeight)
      }()
      self.heightContraintForPendingTransactionListView.constant = viewHeight
      self.transactionTableView.reloadData()
    }
    self.updateViewConstraints()
    self.view.layoutIfNeeded()
  }

  func updatePendingTransactions(_ transactions: [Transaction]) {
    self.pendingTransactions = transactions
    self.updateUI()
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.delegate?.pendingTransactionListViewDidClose()
  }

  @IBAction func exchangeNowButtonPressed(_ sender: Any) {
    self.delegate?.pendingTransactionListViewDidClickExchangeNow()
  }

  @IBAction func transferNowButtonPressed(_ sender: Any) {
    self.delegate?.pendingTransactionListViewDidClickTransferNow()
  }
}

extension KNPendingTransactionListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if self.pendingTransactions.count <= indexPath.row { return }
    let transaction = self.pendingTransactions[indexPath.row]
    self.delegate?.pendingTransactionListViewDidSelectTransaction(transaction)
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }
}

extension KNPendingTransactionListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 0
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.pendingTransactions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if self.pendingTransactions.count <= indexPath.row { return UITableViewCell() }
    let transaction = self.pendingTransactions[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: transactionListCellID, for: indexPath) as! KNPendingTransactionListTableViewCell
    cell.updateCell(with: transaction)
    return cell
  }
}
