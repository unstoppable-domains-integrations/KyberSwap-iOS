// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNWalletViewControllerDelegate: class {
  func walletViewControllerDidExit()
  func walletViewControllerDidClickExchange(token: KNToken)
  func walletViewControllerDidClickTransfer(token: KNToken)
  func walletViewControllerDidClickReceive(token: KNToken)
}

class KNWalletViewController: KNBaseViewController {

  fileprivate weak var delegate: KNWalletViewControllerDelegate?
  fileprivate let tokens: [KNToken] = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
  fileprivate var isHidingSmallAssets: Bool = false

  fileprivate var balances: [String: Balance] = [:]
  fileprivate var totalETHBalance: BigInt = BigInt(0)
  fileprivate var totalUSDBalance: BigInt = BigInt(0)

  fileprivate var expandedRowIDs: [Int] = []

  fileprivate var displayedTokens: [KNToken] {
    let tokens: [KNToken] = {
      if !isHidingSmallAssets { return self.tokens.filter({ return self.balances[$0.address] != nil }) }
      return self.tokens.filter { token -> Bool in
        // Remove <= US$1
        guard let bal = self.balances[token.address], !bal.value.isZero else { return false }
        if let usdRate = KNRateCoordinator.shared.usdRate(for: token), usdRate.rate * bal.value <= BigInt(EthereumUnit.ether.rawValue) {
          return false
        }
        return true
      }
    }()
    return tokens.sorted {
      guard let bal0 = self.balances[$0.address], let bal1 = self.balances[$1.address] else { return false }
      return bal0.value > bal1.value
    }
  }

  @IBOutlet weak var estimatedValueContainerView: UIView!
  @IBOutlet weak var estimatedBalanceAmountLabel: UILabel!

  @IBOutlet weak var hideSmallAssetsButton: UIButton!

  @IBOutlet weak var tokensCollectionView: UICollectionView!

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
    self.setupTokensCollectionView()
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

  fileprivate func setupTokensCollectionView() {
    let nib = UINib(nibName: KNWalletTokenCollectionViewCell.className, bundle: nil)
    self.tokensCollectionView.register(nib, forCellWithReuseIdentifier: KNWalletTokenCollectionViewCell.cellID)

    self.tokensCollectionView.delegate = self
    self.tokensCollectionView.dataSource = self
  }

  @IBAction func hideSmallAssetsButtonPressed(_ sender: Any) {
    self.isHidingSmallAssets = !self.isHidingSmallAssets
    let text = self.isHidingSmallAssets ? "Show small assets" : "Hide small assets"
    self.hideSmallAssetsButton.setTitle(text.toBeLocalised(), for: .normal)
    self.tokensCollectionView.reloadData()
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.walletViewControllerDidExit()
  }
}

extension KNWalletViewController {
  fileprivate func updateViewWhenBalanceDidUpdate() {
    self.tokensCollectionView.reloadData()
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

extension KNWalletViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let index = self.expandedRowIDs.index(of: indexPath.row) {
      self.expandedRowIDs.remove(at: index)
    } else {
      self.expandedRowIDs.append(indexPath.row)
    }
    collectionView.reloadData()
  }
}

extension KNWalletViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 10
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let expandedHeight: CGFloat = KNWalletTokenCollectionViewCell.expandedHeight
    let normalHeight: CGFloat = KNWalletTokenCollectionViewCell.normalHeight
    let height: CGFloat = self.expandedRowIDs.contains(indexPath.row) ? expandedHeight : normalHeight
    return CGSize(width: collectionView.frame.width, height: height)
  }
}

extension KNWalletViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.displayedTokens.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNWalletTokenCollectionViewCell.cellID, for: indexPath) as! KNWalletTokenCollectionViewCell
    let token: KNToken = self.displayedTokens[indexPath.row]
    let balance: Balance = self.balances[token.address] ?? Balance(value: BigInt(0))

    cell.updateCell(
      with: token,
      balance: balance,
      isExpanded: self.expandedRowIDs.contains(indexPath.row),
      delegate: self
    )
    return cell
  }
}

extension KNWalletViewController: KNWalletTokenCollectionViewCellDelegate {
  func walletTokenCollectionViewCellDidClickExchange(token: KNToken) {
    self.delegate?.walletViewControllerDidClickExchange(token: token)
  }

  func walletTokenCollectionViewCellDidClickTransfer(token: KNToken) {
    self.delegate?.walletViewControllerDidClickTransfer(token: token)
  }

  func walletTokenCollectionViewCellDidClickReceive(token: KNToken) {
    self.delegate?.walletViewControllerDidClickReceive(token: token)
  }
}
