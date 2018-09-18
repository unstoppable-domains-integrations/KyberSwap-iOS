// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNListWalletsViewEvent {
  case close
  case select(wallet: KNWalletObject)
  case remove(wallet: KNWalletObject)
  case edit(wallet: KNWalletObject)
  case addWallet
}

protocol KNListWalletsViewControllerDelegate: class {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent)
}

class KNListWalletsViewModel {
  var listWallets: [KNWalletObject] = []
  var curWallet: KNWalletObject

  init(listWallets: [KNWalletObject], curWallet: KNWalletObject) {
    self.listWallets = listWallets
    self.curWallet = curWallet
  }

  var numberRows: Int { return self.listWallets.count }
  func wallet(at row: Int) -> KNWalletObject { return self.listWallets[row] }
  func isCurrentWallet(row: Int) -> Bool { return self.listWallets[row].address == self.curWallet.address }

  func update(wallets: [KNWalletObject], curWallet: KNWalletObject) {
    self.listWallets = wallets
    self.curWallet = curWallet
  }
}

class KNListWalletsViewController: KNBaseViewController {

  fileprivate let kCellID: String = "walletsTableViewCellID"

  weak var delegate: KNListWalletsViewControllerDelegate?
  fileprivate var viewModel: KNListWalletsViewModel

  @IBOutlet weak var walletTableView: UITableView!

  @IBOutlet weak var heightConstraintForWalletTableView: NSLayoutConstraint!
  init(viewModel: KNListWalletsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNListWalletsViewController.className, bundle: nil)
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
    self.setupNavigationBar()
  }

  fileprivate func setupUI() {
    self.setupWalletTableView()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = "Manage Wallet".toBeLocalised()
  }

  fileprivate func setupWalletTableView() {
    let nib = UINib(nibName: KNListWalletsTableViewCell.className, bundle: nil)
    self.walletTableView.register(nib, forCellReuseIdentifier: kCellID)
    self.walletTableView.rowHeight = 68.0
    self.walletTableView.delegate = self
    self.walletTableView.dataSource = self
    self.heightConstraintForWalletTableView.constant = 0
  }

  func updateView(with wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.viewModel.update(wallets: wallets, curWallet: currentWallet)
    self.heightConstraintForWalletTableView.constant = CGFloat(wallets.count) * 68.0
    self.walletTableView.reloadData()
    self.updateViewConstraints()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewController(self, run: .close)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.listWalletsViewController(self, run: .close)
    }
  }

  @IBAction func addButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewController(self, run: .addWallet)
  }
}

extension KNListWalletsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let wallet = self.viewModel.wallet(at: indexPath.row)
    self.delegate?.listWalletsViewController(self, run: .select(wallet: wallet))
  }
}

extension KNListWalletsViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let wallet = self.viewModel.wallet(at: indexPath.row)
    let edit = UITableViewRowAction(style: .normal, title: "Edit".toBeLocalised()) { (_, _) in
      self.delegate?.listWalletsViewController(self, run: .edit(wallet: wallet))
    }
    edit.backgroundColor = UIColor.Kyber.shamrock
    let delete = UITableViewRowAction(style: .destructive, title: "Delete".toBeLocalised()) { (_, _) in
      self.delegate?.listWalletsViewController(self, run: .remove(wallet: wallet))
    }
    delete.backgroundColor = UIColor.Kyber.strawberry
    return [delete, edit]
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath) as! KNListWalletsTableViewCell
    let wallet = self.viewModel.wallet(at: indexPath.row)
    cell.updateCell(with: wallet, id: indexPath.row)
    if self.viewModel.isCurrentWallet(row: indexPath.row) {
      cell.accessoryType = .checkmark
      cell.tintColor = UIColor.Kyber.lightSeaGreen
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
}
