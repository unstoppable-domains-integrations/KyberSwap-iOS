// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNListWalletsViewControllerDelegate: class {
  func listWalletsViewControllerDidClickBackButton()
  func listWalletsViewControllerDidSelectWallet(_ wallet: Wallet)
  func listWalletsViewControllerDidSelectRemoveWallet(_ wallet: Wallet)
  func listWalletsViewControllerDidSelectAddWallet()
}

class KNListWalletsViewController: KNBaseViewController {

  fileprivate let kCellID: String = "walletsTableViewCellID"

  fileprivate weak var delegate: KNListWalletsViewControllerDelegate?
  fileprivate var listWallets: [Wallet] = []
  fileprivate var currentWallet: Wallet!

  @IBOutlet weak var addWalletButton: UIButton!
  @IBOutlet weak var walletTableView: UITableView!

  init(delegate: KNListWalletsViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNListWalletsViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupNaivagationBar()
    self.setupWalletTableView()
    self.setupAddWallet()
  }

  fileprivate func setupNaivagationBar() {
    self.navigationItem.title = "Wallets"
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(self.backButtonPressed(_:)))
    self.navigationItem.backBarButtonItem?.tintColor = .white
  }

  fileprivate func setupWalletTableView() {
    self.walletTableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellID)
    self.walletTableView.rowHeight = 60
    self.walletTableView.delegate = self
    self.walletTableView.dataSource = self
    self.walletTableView.backgroundColor = .white
  }

  fileprivate func setupAddWallet() {
    self.addWalletButton.rounded(color: .clear, width: 0, radius: 10.0)
  }

  func updateView(with wallets: [Wallet], currentWallet: Wallet) {
    self.listWallets = wallets
    self.currentWallet = currentWallet
    self.walletTableView.reloadData()
  }

  @objc func backButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewControllerDidClickBackButton()
  }

  @IBAction func addWalletButtonPressed(_ sender: UIButton) {
  }
}

extension KNListWalletsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.delegate?.listWalletsViewControllerDidSelectWallet(self.listWallets[indexPath.row])
  }
}

extension KNListWalletsViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.listWallets.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return nil
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath)
    cell.textLabel?.text = self.listWallets[indexPath.row].address.description
    cell.backgroundColor = .white
    return cell
  }
}
