// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

enum KNBalanceTabHamburgerMenuViewEvent {
  case select(wallet: KNWalletObject)
  case selectAddWallet
  case selectSendToken
  case selectSettings
  case selectAllTransactions
}

protocol KNBalanceTabHamburgerMenuViewControllerDelegate: class {
  func balanceTabHamburgerMenuViewController(_ controller: KNBalanceTabHamburgerMenuViewController, run event: KNBalanceTabHamburgerMenuViewEvent)
}

struct KNBalanceTabHamburgerMenuViewModel {

  var pendingTransactions: [Transaction] = []
  var wallets: [KNWalletObject]
  var currentWallet: KNWalletObject

  init(
    walletObjects: [KNWalletObject],
    currentWallet: KNWalletObject,
    transactions: [Transaction] = []) {
    self.wallets = walletObjects
    self.currentWallet = currentWallet
    self.pendingTransactions = transactions
  }

  func wallet(at row: Int) -> KNWalletObject {
    return self.wallets[row]
  }

  var numberWalletRows: Int {
    return self.wallets.count
  }

  var walletCellRowHeight: CGFloat {
    return 46.0
  }

  var walletTableViewHeight: CGFloat {
    return self.walletCellRowHeight * CGFloat(self.numberWalletRows)
  }

  mutating func update(wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.wallets = wallets
    self.currentWallet = currentWallet
  }

  func transaction(at row: Int) -> Transaction? {
    if row >= self.pendingTransactions.count { return nil }
    return self.pendingTransactions[row]
  }

  var numberTransactions: Int {
    return min(self.pendingTransactions.count, 2)
  }

  var isTransactionTableHidden: Bool {
    return self.numberTransactions == 0
  }

  mutating func update(transactions: [Transaction]) {
    self.pendingTransactions = transactions
  }
}

class KNBalanceTabHamburgerMenuViewController: KNBaseViewController {

  fileprivate let kWalletTableViewCellID: String = "kKNBalanceTabHamburgerMenuTableViewCellID"
  fileprivate let kPendingTableViewCellID: String = "kPendingTableViewCellID"

  @IBOutlet weak var pendingTransactionContainerView: UIView!
  @IBOutlet weak var noPendingTransactionLabel: UILabel!
  @IBOutlet weak var pendingTableView: UITableView!
  @IBOutlet weak var allTransactionButton: UIButton!

  @IBOutlet weak var hamburgerView: UIView!
  @IBOutlet weak var walletListTableView: UITableView!
  @IBOutlet weak var walletListTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var addWalletButton: UIButton!
  @IBOutlet weak var sendTokenButton: UIButton!
  @IBOutlet weak var settingsButton: UIButton!
  @IBOutlet weak var hamburgerMenuViewTrailingConstraint: NSLayoutConstraint!

  @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
  fileprivate var screenEdgePanRecognizer: UIScreenEdgePanGestureRecognizer?

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

    self.walletListTableView.register(UITableViewCell.self, forCellReuseIdentifier: kWalletTableViewCellID)
    self.walletListTableView.rowHeight = self.viewModel.walletCellRowHeight
    self.walletListTableView.delegate = self
    self.walletListTableView.dataSource = self
    self.walletListTableViewHeightConstraint.constant = viewModel.walletTableViewHeight

    self.pendingTableView.register(UITableViewCell.self, forCellReuseIdentifier: kPendingTableViewCellID)
    self.pendingTableView.rowHeight = 28
    self.pendingTableView.delegate = self
    self.pendingTableView.dataSource = self

    self.update(transactions: self.viewModel.pendingTransactions)

    self.view.layoutIfNeeded()
  }

  // MARK: Update from coordinator
  func updateCurrentWallet(_ currentWallet: KNWalletObject) {
    self.update(
      walletObjects: self.viewModel.wallets,
      currentWallet: currentWallet
    )
  }

  func update(walletObjects: [KNWalletObject], currentWallet: KNWalletObject) {
    self.viewModel.update(wallets: walletObjects, currentWallet: currentWallet)
    self.walletListTableViewHeightConstraint.constant = viewModel.walletTableViewHeight
    self.walletListTableView.reloadData()
    self.pendingTableView.reloadData()
    self.view.layoutIfNeeded()
  }

  func update(transactions: [Transaction]) {
    self.viewModel.update(transactions: transactions)
    self.pendingTableView.isHidden = self.viewModel.isTransactionTableHidden
    self.noPendingTransactionLabel.isHidden = !self.viewModel.isTransactionTableHidden
    if !self.pendingTableView.isHidden { self.pendingTableView.reloadData() }
  }

  func openMenu(animated: Bool, completion: (() -> Void)? = nil) {
    self.view.isHidden = false
    self.hamburgerMenuViewTrailingConstraint.constant = 0
    let duration: TimeInterval = animated ? 0.3 : 0
    UIView.animate(withDuration: duration, animations: {
      self.view.alpha = 1
      self.view.layoutIfNeeded()
    }, completion: { _ in
      self.screenEdgePanRecognizer?.isEnabled = false
      self.panGestureRecognizer.isEnabled = true
      self.walletListTableView.reloadData()
      self.pendingTableView.reloadData()
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
      self.screenEdgePanRecognizer?.isEnabled = true
      self.panGestureRecognizer.isEnabled = false
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

  @IBAction func addWalletButtonPressed(_ sender: Any) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectAddWallet)
    }
  }

  @IBAction func sendTokenButtonPressed(_ sender: Any) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectSendToken)
    }
  }

  @IBAction func settingsButtonPressed(_ sender: Any) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectSettings)
    }
  }

  @IBAction func allTransactionButtonPressed(_ sender: Any) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectAllTransactions)
    }
  }

  func gestureScreenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if self.screenEdgePanRecognizer == nil { self.screenEdgePanRecognizer = sender }
    switch sender.state {
    case .began:
      self.view.isHidden = false
      self.view.alpha = 0
    case .changed:
      let translationX = -sender.translation(in: sender.view).x
      if -self.hamburgerView.frame.width + translationX >= 0 {
        self.hamburgerMenuViewTrailingConstraint.constant = 0
        self.view.alpha = 1
      } else if translationX < 0 {
        self.hamburgerMenuViewTrailingConstraint.constant = -self.hamburgerView.frame.width
        self.view.alpha = 0
      } else {
        self.hamburgerMenuViewTrailingConstraint.constant = -self.hamburgerView.frame.width + translationX
        let ratio = translationX / self.hamburgerView.frame.width
        self.view.alpha = ratio
      }
      self.view.layoutIfNeeded()
    default:
      if self.hamburgerMenuViewTrailingConstraint.constant < -self.hamburgerView.frame.width / 2 {
        self.hideMenu(animated: true)
      } else {
        self.openMenu(animated: true)
      }
    }
  }

  @IBAction func gesturePanActionRecognized(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      //do nothing here
      print("Pan gesture began")
    case .changed:
      let translationX = sender.translation(in: sender.view).x
      if translationX <= 0 {
        self.hamburgerMenuViewTrailingConstraint.constant = 0
        self.view.alpha = 1
      } else if self.hamburgerView.frame.width - translationX <= 0 {
        self.hamburgerMenuViewTrailingConstraint.constant = -self.hamburgerView.frame.width
        self.view.alpha = 0
      } else {
        self.hamburgerMenuViewTrailingConstraint.constant = -translationX
        let ratio = (self.hamburgerView.frame.width - translationX) / self.hamburgerView.frame.width
        self.view.alpha = ratio
      }
      self.view.layoutIfNeeded()
    default:
      if self.hamburgerMenuViewTrailingConstraint.constant < -self.hamburgerView.frame.width / 2 {
        self.hideMenu(animated: true)
      } else {
        self.openMenu(animated: true)
      }
    }
  }
}

extension KNBalanceTabHamburgerMenuViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if tableView == self.walletListTableView {
      let wallet = self.viewModel.wallet(at: indexPath.row)
      self.hideMenu(animated: true) {
        if wallet != self.viewModel.currentWallet {
          self.delegate?.balanceTabHamburgerMenuViewController(self, run: .select(wallet: wallet))
        }
      }
    } else {
      let tx = self.viewModel.transaction(at: indexPath.row)?.id ?? ""
      if let url = URL(string: KNEnvironment.default.etherScanIOURLString + "tx/\(tx)") {
        self.hideMenu(animated: true) {
          let safariVC = SFSafariViewController(url: url)
          self.present(safariVC, animated: true, completion: nil)
        }
      }
    }
  }
}

extension KNBalanceTabHamburgerMenuViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if tableView == self.walletListTableView {
      return self.viewModel.numberWalletRows
    }
    return self.viewModel.numberTransactions
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView == self.walletListTableView {
      let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath)
      cell.imageView?.isUserInteractionEnabled = true
      cell.textLabel?.isUserInteractionEnabled = true
      let wallet = self.viewModel.wallet(at: indexPath.row)
      cell.imageView?.image = UIImage(named: wallet.icon)
      cell.textLabel?.text = wallet.name
      if wallet == self.viewModel.currentWallet {
        cell.backgroundColor = UIColor(hex: "edfbf6")
        cell.accessoryType = .checkmark
      } else {
        cell.backgroundColor = .clear
        cell.accessoryType = .none
      }
      return cell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: kPendingTableViewCellID, for: indexPath)
    cell.imageView?.isUserInteractionEnabled = true
    cell.textLabel?.isUserInteractionEnabled = true
    cell.imageView?.image = UIImage(named: "loading_icon")
    let transaction = self.viewModel.transaction(at: indexPath.row)
    cell.imageView?.startRotating()
    cell.textLabel?.text = transaction?.shortDesc
    cell.backgroundColor = UIColor.clear
    return cell
  }
}

// to be able select table view cell
extension KNBalanceTabHamburgerMenuViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return !(touch.view?.isDescendant(of: self.walletListTableView) == true || touch.view?.isDescendant(of: self.pendingTableView) == true)
  }
}
