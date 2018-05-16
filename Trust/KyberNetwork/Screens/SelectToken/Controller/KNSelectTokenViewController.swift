// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNSelectTokenViewControllerDelegate: class {
  func selectTokenViewUserDidSelect(_ token: TokenObject)
}

class KNSelectTokenViewController: KNBaseViewController {

  fileprivate let selectTokenCellID = "selectTokenCellID"
  fileprivate let selectTokenCellHeight: CGFloat = 60.0

  fileprivate weak var delegate: KNSelectTokenViewControllerDelegate?

  fileprivate var availableTokens: [TokenObject] = []
  fileprivate var tokenBalances: [String: Balance] = [:]

  @IBOutlet weak var tokenTableView: UITableView!

  init(delegate: KNSelectTokenViewControllerDelegate?, availableTokens: [TokenObject]) {
    self.delegate = delegate
    self.availableTokens = availableTokens
    super.init(nibName: KNSelectTokenViewController.className, bundle: nil)
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
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.sortTokensByBalances()
    self.tokenTableView.reloadData()
  }

  fileprivate func setupUI() {
    self.navigationItem.title = "Select Token".toBeLocalised()
    self.tokenTableView.backgroundColor = UIColor.clear
    let nib = UINib(nibName: KNSelectTokenTableViewCell.className, bundle: nil)
    self.tokenTableView.register(nib, forCellReuseIdentifier: selectTokenCellID)
    self.tokenTableView.rowHeight = selectTokenCellHeight
    self.tokenTableView.delegate = self
    self.tokenTableView.dataSource = self
  }

  fileprivate func sortTokensByBalances() {
    self.availableTokens.sort { (token1, token2) -> Bool in
      let balance1 = self.tokenBalances[token1.contract] ?? Balance(value: BigInt(0))
      let balance2 = self.tokenBalances[token2.contract] ?? Balance(value: BigInt(0))
      return balance1.value > balance2.value || (balance1.value == balance2.value && token1.contract < token2.contract)
    }
    self.tokenTableView.reloadData()
  }

  func updateETHBalance(_ balance: Balance) {
    if let eth = self.availableTokens.first(where: { $0.isETH }) {
      self.tokenBalances[eth.contract] = balance
    }
    if self.tokenTableView != nil { self.sortTokensByBalances() }
  }

  func updateTokenBalances(_ balances: [String: Balance]) {
    for (key, value) in balances {
      self.tokenBalances[key] = value
    }
    if self.tokenTableView != nil { self.sortTokensByBalances() }
  }

  @objc func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
}

extension KNSelectTokenViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let token = self.availableTokens[indexPath.row]
    tableView.deselectRow(at: indexPath, animated: false)
    self.delegate?.selectTokenViewUserDidSelect(token)
  }
}

extension KNSelectTokenViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.availableTokens.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let token = self.availableTokens[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: selectTokenCellID, for: indexPath) as! KNSelectTokenTableViewCell
    let balance = self.tokenBalances[token.contract] ?? Balance(value: BigInt(0))
    cell.updateCell(with: token, balance: balance)
    return cell
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }
}
