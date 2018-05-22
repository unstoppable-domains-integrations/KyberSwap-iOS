// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNBalanceTabHamburgerMenuViewControllerDelegate: class {
  func balanceTabHamburgerMenuDidSelect(walelt: KNWalletObject, sender: KNBalanceTabHamburgerMenuViewController)
  func balanceTabHamburgerMenuDidSelectManageWallet(sender: KNBalanceTabHamburgerMenuViewController)
  func balanceTabHamburgerMenuDidSelectSettings(sender: KNBalanceTabHamburgerMenuViewController)
}

struct KNBalanceTabHamburgerMenuViewModel {
  var wallets: [KNWalletObject]
  var currentWallet: KNWalletObject

  init(walletObjects: [KNWalletObject], currentWallet: KNWalletObject) {
    self.wallets = walletObjects
    self.currentWallet = currentWallet
  }

  func wallet(at row: Int) -> KNWalletObject {
    return self.wallets[row]
  }

  var numberRows: Int {
    return self.wallets.count
  }

  var rowHeight: CGFloat {
    return 46.0
  }

  var tableViewHeight: CGFloat {
    return self.rowHeight * CGFloat(self.numberRows)
  }

  mutating func update(wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.wallets = wallets
    self.currentWallet = currentWallet
  }
}

class KNBalanceTabHamburgerMenuViewController: KNBaseViewController {

  fileprivate let cellID: String = "KNBalanceTabHamburgerMenuTableViewCellID"

  @IBOutlet weak var hamburgerView: UIView!
  @IBOutlet weak var walletListTableView: UITableView!
  @IBOutlet weak var walletListTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var manageWalletButton: UIButton!
  @IBOutlet weak var settingsButton: UIButton!
  @IBOutlet weak var hamburgerMenuViewTrailingConstraint: NSLayoutConstraint!

  fileprivate var viewModel: KNBalanceTabHamburgerMenuViewModel
  weak var delegate: KNBalanceTabHamburgerMenuViewControllerDelegate?

  init(viewModel: KNBalanceTabHamburgerMenuViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNBalanceTabHamburgerMenuViewController.className, bundle: nil)
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
    self.view.isUserInteractionEnabled = true
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.backgroundViewTap(_:)))
    tapGesture.delegate = self
    self.view.addGestureRecognizer(tapGesture)

    self.manageWalletButton.rounded(radius: 4.0)
    self.settingsButton.rounded(radius: 4.0)

    self.walletListTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
    self.walletListTableView.rowHeight = self.viewModel.rowHeight
    self.walletListTableView.delegate = self
    self.walletListTableView.dataSource = self
    self.walletListTableViewHeightConstraint.constant = viewModel.tableViewHeight

    self.view.layoutIfNeeded()
  }

  func update(walletObjects: [KNWalletObject], currentWallet: KNWalletObject) {
    self.viewModel.update(wallets: walletObjects, currentWallet: currentWallet)
    self.walletListTableViewHeightConstraint.constant = viewModel.tableViewHeight
    self.walletListTableView.reloadData()
    self.view.layoutIfNeeded()
  }

  func openMenu(animated: Bool, completion: (() -> Void)? = nil) {
    self.view.isHidden = false
    self.hamburgerMenuViewTrailingConstraint.constant = 0
    let duration: TimeInterval = animated ? 0.3 : 0
    UIView.animate(withDuration: duration, animations: {
      self.view.alpha = 1
      self.view.layoutIfNeeded()
    }, completion: { _ in
      self.walletListTableView.reloadData()
      completion?()
    })
  }

  func hideMenu(animated: Bool, completion: (() -> Void)? = nil) {
    self.hamburgerMenuViewTrailingConstraint.constant = -self.hamburgerView.frame.width
    let duration: TimeInterval = animated ? 0.3 : 0
    UIView.animate(withDuration: duration, animations: {
      self.view.alpha = 0
      self.view.layoutIfNeeded()
    }, completion: { _ in
      self.view.isHidden = true
      completion?()
    })
  }

  @objc func backgroundViewTap(_ recognizer: UITapGestureRecognizer) {
    let point = recognizer.location(in: self.view)
    if point.x <= self.view.frame.width - self.hamburgerView.frame.width {
      self.hideMenu(animated: true)
    }
  }

  @IBAction func manageWalletButtonPressed(_ sender: Any) {
    self.delegate?.balanceTabHamburgerMenuDidSelectManageWallet(sender: self)
  }

  @IBAction func settingsButtonPressed(_ sender: Any) {
    self.delegate?.balanceTabHamburgerMenuDidSelectSettings(sender: self)
  }
}

extension KNBalanceTabHamburgerMenuViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let wallet = self.viewModel.wallet(at: indexPath.row)
    self.hideMenu(animated: true) {
      if wallet != self.viewModel.currentWallet {
        self.delegate?.balanceTabHamburgerMenuDidSelect(walelt: wallet, sender: self)
      }
    }
  }
}

extension KNBalanceTabHamburgerMenuViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
    let wallet = self.viewModel.wallet(at: indexPath.row)
    cell.imageView?.image = UIImage(named: wallet.icon)
    cell.textLabel?.text = wallet.name
    cell.backgroundColor = .clear
    if wallet == self.viewModel.currentWallet {
      cell.accessoryType = .checkmark
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
}

// to be able select table view cell
extension KNBalanceTabHamburgerMenuViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return !(touch.view?.isDescendant(of: self.walletListTableView) == true)
  }
}
