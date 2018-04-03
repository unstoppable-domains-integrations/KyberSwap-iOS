// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNWalletViewControllerDelegate: class {
  func walletViewControllerDidExit()
}

class KNWalletViewController: KNBaseViewController {

  fileprivate weak var delegate: KNWalletViewControllerDelegate?
  fileprivate let tokens: [KNToken] = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
  fileprivate var isHidingSmallAssets: Bool = false

  fileprivate var balances: [String: Balance] = [:]
  fileprivate var totalETHBalance: BigInt = BigInt(0)
  fileprivate var totalUSDBalance: BigInt = BigInt(0)

  fileprivate var displayedTokens: [KNToken] {
    if !isHidingSmallAssets { return self.tokens }
    return self.tokens.filter { token -> Bool in
      guard let bal = self.balances[token.address], !bal.value.isZero else { return false }
      return true
    }
  }

  @IBOutlet weak var estimatedValueContainerView: UIView!
  @IBOutlet weak var estimatedBalanceAmountLabel: UILabel!

  @IBOutlet weak var hideSmallAssetsButton: UIButton!

  @IBOutlet weak var tokensTableView: UITableView!

  init(delegate: KNWalletViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNWalletViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupEstimatedTotalValue()
    self.setupSmallAssets()
    self.setupTokensTableView()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = "Wallet"
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .plain, target: self, action: #selector(self.exitButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
  }

  fileprivate func setupEstimatedTotalValue() {
    self.estimatedBalanceAmountLabel.text = "0 ETH = 0 USD"
    self.estimatedValueContainerView.rounded(color: UIColor.Kyber.gray, width: 0.5, radius: 0)
  }

  fileprivate func setupSmallAssets() {
    let text = self.isHidingSmallAssets ? "Show small assets" : "Hide small assets"
    self.hideSmallAssetsButton.setTitle(text.toBeLocalised(), for: .normal)
  }

  fileprivate func setupTokensTableView() {
    let nib = UINib(nibName: KNWalletTokenTableViewCell.className, bundle: nil)
    self.tokensTableView.register(nib, forCellReuseIdentifier: KNWalletTokenTableViewCell.cellID)
    self.tokensTableView.estimatedRowHeight = 80.0
    self.tokensTableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

    self.tokensTableView.delegate = self
    self.tokensTableView.dataSource = self
  }

  @IBAction func hideSmallAssetsButtonPressed(_ sender: Any) {
    self.isHidingSmallAssets = !self.isHidingSmallAssets
    let text = self.isHidingSmallAssets ? "Show small assets" : "Hide small assets"
    self.hideSmallAssetsButton.setTitle(text.toBeLocalised(), for: .normal)
    self.tokensTableView.reloadData()
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.walletViewControllerDidExit()
  }
}

extension KNWalletViewController {
  fileprivate func updateViewWhenBalanceDidUpdate() {
    self.tokensTableView.reloadData()
    self.view.layoutIfNeeded()
  }

  fileprivate func updateEstimatedTotalValue() {
    let ethString = "ETH \(EtherNumberFormatter.short.string(from: self.totalETHBalance))"
    let usdString = "USD \(EtherNumberFormatter.short.string(from: self.totalUSDBalance))"
    self.estimatedBalanceAmountLabel.text = "\(ethString) = \(usdString)"
  }

  func coordinatorUpdateTokenBalances(_ balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    self.updateViewWhenBalanceDidUpdate()
  }

  func coordinatorUpdateBalanceInETHAndUSD(ethBalance: BigInt, usdBalance: BigInt) {
    self.totalETHBalance = ethBalance
    self.totalUSDBalance = usdBalance
    self.updateEstimatedTotalValue()
  }
}

extension KNWalletViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }
}

extension KNWalletViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.displayedTokens.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: KNWalletTokenTableViewCell.cellID, for: indexPath) as! KNWalletTokenTableViewCell
    let token: KNToken = self.displayedTokens[indexPath.row]
    let balance: Balance = self.balances[token.address] ?? Balance(value: BigInt(0))
    cell.updateCell(with: token, balance: balance)
    return cell
  }
}
