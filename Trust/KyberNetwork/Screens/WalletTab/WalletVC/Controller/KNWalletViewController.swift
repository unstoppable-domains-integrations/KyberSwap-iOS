// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNWalletViewControllerDelegate: class {
  func walletViewController(_ controller: KNWalletViewController, didExit sender: Any)
  func walletViewController(_ controller: KNWalletViewController, didClickAddTokenManually sender: Any)
  func walletViewController(_ controller: KNWalletViewController, didClickWallet sender: Any)
  func walletViewController(_ controller: KNWalletViewController, didClickExchange token: TokenObject)
  func walletViewController(_ controller: KNWalletViewController, didClickTransfer token: TokenObject)
  func walletViewController(_ controller: KNWalletViewController, didClickReceive token: TokenObject)
}

class KNWalletViewController: KNBaseViewController {

  fileprivate weak var delegate: KNWalletViewControllerDelegate?
  fileprivate let tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  fileprivate var tokenObjects: [TokenObject] = []
  fileprivate var displayedTokens: [TokenObject] = []
  fileprivate var coinTickers: [KNCoinTicker?] = []
  fileprivate var usdRates: [KNRate?] = []
  fileprivate var isHidingSmallAssets: Bool = false

  fileprivate var balances: [String: Balance] = [:]
  fileprivate var totalETHBalance: BigInt = BigInt(0)
  fileprivate var totalUSDBalance: BigInt = BigInt(0)

  fileprivate var expandedRowIDs: [Int] = []

  fileprivate lazy var exchangeTokens: [(TokenObject, TokenObject?)] = {
    var result: [(TokenObject, TokenObject?)] = []
    guard let eth = self.tokens.first(where: { $0.isETH }) else { return result }
    self.tokens.forEach({ if !$0.isETH { result.append(($0, eth)) } })
    self.tokens.forEach({ if !$0.isETH { result.append((eth, $0)) } })
    self.tokens.forEach({ result.append(($0, nil)) })
    return result
  }()

  @IBOutlet weak var estimatedValueContainerView: UIView!
  @IBOutlet weak var estimatedBalanceAmountLabel: UILabel!

  @IBOutlet weak var hideSmallAssetsButton: UIButton!

  @IBOutlet weak var tokensCollectionView: UICollectionView!
  @IBOutlet weak var exchangeRateCollectionView: UICollectionView!
  @IBOutlet weak var heightConstraintForExchangeRateCollectionView: NSLayoutConstraint!

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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.setupNavigationBar()
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupEstimatedTotalValue()
    self.setupSmallAssets()
    self.setupExchangeRateCollectionView()
    self.setupTokensCollectionView()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = "Wallet".toBeLocalised()
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit".toBeLocalised(), style: .plain, target: self, action: #selector(self.exitButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add".toBeLocalised(), style: .plain, target: self, action: #selector(self.addTokenManuallyPressed(_:)))
    self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
  }

  fileprivate func setupEstimatedTotalValue() {
    self.estimatedBalanceAmountLabel.text = "ETH 0 = USD $0"
    self.estimatedValueContainerView.rounded(color: UIColor.Kyber.gray, width: 0.5, radius: 0)
    UITapGestureRecognizer(addToView: self.estimatedValueContainerView) {
      self.delegate?.walletViewController(self, didClickWallet: self.estimatedValueContainerView)
    }
  }

  fileprivate func setupSmallAssets() {
    let text = self.isHidingSmallAssets ? "Show small assets" : "Hide small assets"
    self.hideSmallAssetsButton.setTitle(text.toBeLocalised(), for: .normal)
  }

  fileprivate func setupExchangeRateCollectionView() {
    let nib = UINib(nibName: KNExchangeRateCollectionViewCell.className, bundle: nil)
    self.exchangeRateCollectionView.register(nib, forCellWithReuseIdentifier: KNExchangeRateCollectionViewCell.cellID)

    self.exchangeRateCollectionView.delegate = self
    self.exchangeRateCollectionView.dataSource = self
    self.exchangeRateCollectionView.isHidden = true
    self.heightConstraintForExchangeRateCollectionView.constant = 0
  }

  fileprivate func setupTokensCollectionView() {
    let nib = UINib(nibName: KNWalletTokenCollectionViewCell.className, bundle: nil)
    self.tokensCollectionView.register(nib, forCellWithReuseIdentifier: KNWalletTokenCollectionViewCell.cellID)

    self.tokensCollectionView.delegate = self
    self.tokensCollectionView.dataSource = self

    self.reloadTokensCollectionView()
  }

  @IBAction func hideSmallAssetsButtonPressed(_ sender: Any) {
    self.isHidingSmallAssets = !self.isHidingSmallAssets
    let text = self.isHidingSmallAssets ? "Show small assets" : "Hide small assets"
    self.hideSmallAssetsButton.setTitle(text.toBeLocalised(), for: .normal)
    self.reloadTokensCollectionView()
  }

  @IBAction func exchangeRateButtonPressed(_ sender: Any) {
    if self.exchangeRateCollectionView.isHidden {
      self.exchangeRateCollectionView.isHidden = false
      self.heightConstraintForExchangeRateCollectionView.constant = KNExchangeRateCollectionViewCell.cellHeight
    } else {
      self.exchangeRateCollectionView.isHidden = true
      self.heightConstraintForExchangeRateCollectionView.constant = 0
    }
    UIView.animate(withDuration: 0.2) {
      self.exchangeRateCollectionView.reloadData()
      self.view.layoutIfNeeded()
    }
  }

  @IBAction func openWalletDetailsButtonPressed(_ sender: Any) {
    self.delegate?.walletViewController(self, didClickWallet: sender)
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.walletViewController(self, didExit: sender)
  }

  @objc func addTokenManuallyPressed(_ sender: Any) {
    self.delegate?.walletViewController(self, didClickAddTokenManually: sender)
  }

  private func reloadTokensCollectionView() {
    let coinTickers = KNCoinTickerStorage.shared.coinTickers
    // Compute displayed token objects
    // 1. Not hide small assets, just return all tokens
    // 2. Hide small assets, return tokens with value USD >= $1
    self.displayedTokens = {
      let tokens: [TokenObject] = {
        if !self.isHidingSmallAssets { return self.tokenObjects }
        return self.tokenObjects.filter { token -> Bool in
          // Remove <= US$1
          guard let bal = self.balances[token.contract], !bal.value.isZero else { return false }
          if let coinTicker = coinTickers.first(where: { $0.isData(for: token) }) {
            let usdRate = KNRate.rateUSD(from: coinTicker)
            return usdRate.rate * bal.value / BigInt(EthereumUnit.ether.rawValue) <= BigInt(EthereumUnit.ether.rawValue)
          }
          return true
        }
      }()
      return tokens.sorted {
        guard let bal0 = self.balances[$0.contract], let bal1 = self.balances[$1.contract] else { return false }
        return bal0.value > bal1.value
      }
    }()
    self.coinTickers = []
    self.usdRates = []

    // Compute cointickers and usdrates for each tokens to improve reload time for collection view cell
    self.displayedTokens.forEach { token in
      let coinTicker: KNCoinTicker? = {
        let tickers = coinTickers.filter { return $0.symbol == token.symbol }
        if tickers.count == 1 { return tickers[0] }
        return tickers.first(where: { $0.name.replacingOccurrences(of: " ", with: "").lowercased() == token.name.lowercased() })
      }()
      self.coinTickers.append(coinTicker)
      if let coinTicker = coinTicker {
        self.usdRates.append(KNRate.rateUSD(from: coinTicker))
      } else {
        self.usdRates.append(nil)
      }
    }
    self.tokensCollectionView.reloadData()
  }
}

extension KNWalletViewController {
  fileprivate func updateViewWhenBalanceDidUpdate() {
    self.reloadTokensCollectionView()
    self.view.layoutIfNeeded()
  }

  fileprivate func updateEstimatedTotalValue() {
    let ethString = "ETH \(EtherNumberFormatter.short.string(from: self.totalETHBalance))"
    let usdString = "USD $\(EtherNumberFormatter.short.string(from: self.totalUSDBalance))"
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

  func coordinatorUpdateTokenObjects(_ tokenObjects: [TokenObject]) {
    if self.tokenObjects == tokenObjects { return }
    self.tokenObjects = tokenObjects
    self.reloadTokensCollectionView()
  }

  func coordinatorCoinTickerDidUpdate() {
    self.reloadTokensCollectionView()
  }
}

extension KNWalletViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if collectionView == self.tokensCollectionView {
      if let index = self.expandedRowIDs.index(of: indexPath.row) {
        self.expandedRowIDs.remove(at: index)
      } else {
        self.expandedRowIDs.append(indexPath.row)
      }
      collectionView.reloadItems(at: [indexPath])
    }
  }
}

extension KNWalletViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return collectionView == self.tokensCollectionView ? 10 : 20
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    if collectionView == self.tokensCollectionView {
      return UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
    }
    return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if collectionView == self.tokensCollectionView {
      let expandedHeight: CGFloat = KNWalletTokenCollectionViewCell.expandedHeight
      let normalHeight: CGFloat = KNWalletTokenCollectionViewCell.normalHeight
      let height: CGFloat = self.expandedRowIDs.contains(indexPath.row) ? expandedHeight : normalHeight
      return CGSize(
        width: collectionView.frame.width,
        height: height
      )
    }
    return CGSize(
      width: KNExchangeRateCollectionViewCell.cellWidth,
      height: KNExchangeRateCollectionViewCell.cellHeight
    )
  }
}

extension KNWalletViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if collectionView == self.tokensCollectionView {
      return self.displayedTokens.count
    }
    return self.exchangeTokens.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if collectionView == self.tokensCollectionView {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNWalletTokenCollectionViewCell.cellID, for: indexPath) as! KNWalletTokenCollectionViewCell

      let tokenObject: TokenObject = self.displayedTokens[indexPath.row]
      let coinTicker: KNCoinTicker? = self.coinTickers[indexPath.row]
      let usdRate: KNRate? = self.usdRates[indexPath.row]
      let balance: Balance = self.balances[tokenObject.contract] ?? Balance(value: BigInt(0))

      cell.updateCell(
        with: tokenObject,
        balance: balance,
        coinTicker: coinTicker,
        usdRate: usdRate,
        isExpanded: self.expandedRowIDs.contains(indexPath.row),
        delegate: self
      )
      return cell
    }
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNExchangeRateCollectionViewCell.cellID, for: indexPath) as! KNExchangeRateCollectionViewCell
    let data = self.exchangeTokens[indexPath.row]
    cell.updateCell(with: data.0, dest: data.1)
    return cell
  }
}

extension KNWalletViewController: KNWalletTokenCollectionViewCellDelegate {
  func walletTokenCollectionViewCellDidClickExchange(token: TokenObject) {
    self.delegate?.walletViewController(self, didClickExchange: token)
  }

  func walletTokenCollectionViewCellDidClickTransfer(token: TokenObject) {
    self.delegate?.walletViewController(self, didClickTransfer: token)
  }

  func walletTokenCollectionViewCellDidClickReceive(token: TokenObject) {
    self.delegate?.walletViewController(self, didClickReceive: token)
  }
}
