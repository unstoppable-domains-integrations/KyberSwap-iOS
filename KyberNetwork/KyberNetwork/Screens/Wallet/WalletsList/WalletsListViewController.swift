//
//  WalletsListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/20/20.
//

import UIKit
import MBProgressHUD

enum WalletsListViewEvent {
  case select(wallet: KNWalletObject)
  case remove(wallet: KNWalletObject)
  case edit(wallet: KNWalletObject)
  case copy(wallet: KNWalletObject)
  case manageWallet
  case connectWallet
}

protocol WalletsListViewControllerDelegate: class {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent)
}

class WalletsListViewModel {
  var wallets: [KNWalletObject]
  var currentWallet: KNWalletObject

  init(
    walletObjects: [KNWalletObject],
    currentWallet: KNWalletObject
    ) {
    self.wallets = walletObjects
    self.currentWallet = currentWallet
  }

  func update(wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.wallets = wallets
    self.currentWallet = currentWallet
  }

  var walletCellRowHeight: CGFloat {
    return 56.0
  }

  func wallet(at row: Int) -> KNWalletObject {
    return self.wallets[row]
  }

  var numberWalletRows: Int {
    return self.wallets.count
  }
  
  var walletTableViewHeight: CGFloat {
    return min(280.0, self.walletCellRowHeight * CGFloat(self.numberWalletRows))
  }
  
  func isCurrentWallet(row: Int) -> Bool { return self.wallets[row].address == self.currentWallet.address }
}

class WalletsListViewController: KNBaseViewController {
  @IBOutlet weak var popupTitle: UILabel!
  @IBOutlet weak var walletTableView: UITableView!
  @IBOutlet weak var manageWalletButton: UIButton!
  @IBOutlet weak var connectWalletButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletsTableViewHeightContraint: NSLayoutConstraint!
  
  fileprivate var viewModel: WalletsListViewModel
  
  fileprivate let kWalletTableViewCellID: String = "WalletListTableViewCell"
  let transitor = TransitionDelegate()
  weak var delegate: WalletsListViewControllerDelegate?
  
  init(viewModel: WalletsListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: WalletsListViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: WalletListTableViewCell.className, bundle: nil)
    self.walletTableView.register(nib, forCellReuseIdentifier: kWalletTableViewCellID)

    self.walletTableView.rowHeight = self.viewModel.walletCellRowHeight
    self.walletsTableViewHeightContraint.constant = self.viewModel.walletTableViewHeight
    self.walletTableView.allowsSelection = true
  }

  func updateView(with wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.viewModel.update(wallets: wallets, currentWallet: currentWallet)
    self.walletTableView.reloadData()
    self.walletsTableViewHeightContraint.constant = self.viewModel.walletTableViewHeight
    self.view.layoutIfNeeded()
  }

  @IBAction func manageWalletButtonTapped(_ sender: UIButton) {
  }
  
  @IBAction func connectWalletButtonTapped(_ sender: UIButton) {
  }
  
  @IBAction func tapView(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
}

extension WalletsListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberWalletRows
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath) as! WalletListTableViewCell
    let wallet = self.viewModel.wallet(at: indexPath.row)
    cell.delegate = self
    cell.updateCell(with: wallet, id: indexPath.row)
    return cell
  }
}

extension WalletsListViewController: WalletListTableViewCellDelegate {
  func walletListTableViewCell(_ controller: WalletListTableViewCell, run event: WalletListTableViewCellEvent) {
    switch event {
    case .copy(let index):
      let wallet = self.viewModel.wallet(at: index)
      self.delegate?.walletsListViewController(self, run: .copy(wallet: wallet))
    case .edit(let index):
      let wallet = self.viewModel.wallet(at: index)
      self.delegate?.walletsListViewController(self, run: .edit(wallet: wallet))
    case .remove(let index):
      let wallet = self.viewModel.wallet(at: index)
      self.delegate?.walletsListViewController(self, run: .remove(wallet: wallet))
    case .select(let index):
      let wallet = self.viewModel.wallet(at: index)
      self.delegate?.walletsListViewController(self, run: .select(wallet: wallet))
    }
  }
}

extension WalletsListViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return self.viewModel.walletTableViewHeight + 213
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
