// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNListWalletsViewControllerDelegate: class {
  func listWalletsViewControllerDidClickBackButton()
  func listWalletsViewControllerDidSelectWallet(_ wallet: Wallet)
  func listWalletsViewControllerDidSelectRemoveWallet(_ wallet: Wallet)
}

class KNListWalletsViewController: KNBaseViewController {

  fileprivate let kCellID: String = "walletsTableViewCellID"

  fileprivate weak var delegate: KNListWalletsViewControllerDelegate?
  fileprivate var listWallets: [Wallet] = []
  fileprivate var currentWallet: Wallet!

  @IBOutlet weak var walletTableView: UITableView!

  @IBOutlet weak var heightConstraintForWalletTableView: NSLayoutConstraint!
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

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.setupNaivagationBar()
  }

  fileprivate func setupUI() {
    self.setupWalletTableView()
  }

  fileprivate func setupNaivagationBar() {
    self.navigationItem.title = "Wallets"
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(self.backButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = .white
  }

  fileprivate func setupWalletTableView() {
    let nib = UINib(nibName: KNListWalletsTableViewCell.className, bundle: nil)
    self.walletTableView.register(nib, forCellReuseIdentifier: kCellID)
    self.walletTableView.rowHeight = 60.0
    self.walletTableView.delegate = self
    self.walletTableView.dataSource = self
    self.walletTableView.backgroundColor = .white
    self.heightConstraintForWalletTableView.constant = 0
  }

  func updateView(with wallets: [Wallet], currentWallet: Wallet) {
    self.listWallets = wallets
    self.currentWallet = currentWallet
    self.heightConstraintForWalletTableView.constant = CGFloat(wallets.count) * 60.0
    self.walletTableView.reloadData()
    self.updateViewConstraints()
  }

  @objc func backButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewControllerDidClickBackButton()
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
    return UIView()
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let wallet = self.listWallets[indexPath.row]
      self.delegate?.listWalletsViewControllerDidSelectRemoveWallet(wallet)
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath) as! KNListWalletsTableViewCell
    let wallet = self.listWallets[indexPath.row]
    if let walletObject = KNWalletStorage.shared.get(forPrimaryKey: wallet.address.description) {
      cell.updateCell(with: walletObject)
    } else {
      let walletObject = KNWalletObject(address: wallet.address.description)
      KNWalletStorage.shared.add(wallets: [walletObject])
      cell.updateCell(with: walletObject)
    }
    if wallet == self.currentWallet {
      cell.accessoryType = .checkmark
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
}
