// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KWalletBalanceViewEvent {
  case openQRCode
  case selectToken(token: TokenObject)
  case openMarketView
}

protocol KWalletBalanceViewControllerDelegate: class {
  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run event: KWalletBalanceViewEvent)
  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run menuEvent: KNBalanceTabHamburgerMenuViewEvent)
}

class KWalletBalanceViewController: KNBaseViewController {

  fileprivate var isViewSetup: Bool = false

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var balanceTextLabel: UILabel!
  @IBOutlet weak var balanceValueLabel: UILabel!
  @IBOutlet weak var walletNameLabel: UILabel!

  @IBOutlet weak var usdButton: UIButton!
  @IBOutlet weak var ethButton: UIButton!
  @IBOutlet weak var searchTextField: UITextField!

  @IBOutlet weak var tokensBalanceCollectionView: UICollectionView!

  fileprivate var viewModel: KWalletBalanceViewModel
  weak var delegate: KWalletBalanceViewControllerDelegate?

  lazy var hamburgerMenu: KNBalanceTabHamburgerMenuViewController = {
    let viewModel = KNBalanceTabHamburgerMenuViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.wallet
    )
    let hamburgerVC = KNBalanceTabHamburgerMenuViewController(viewModel: viewModel)
    hamburgerVC.view.frame = self.view.bounds
    hamburgerVC.view.isHidden = true
    self.view.addSubview(hamburgerVC.view)
    self.addChildViewController(hamburgerVC)
    hamburgerVC.didMove(toParentViewController: self)
    hamburgerVC.delegate = self
    return hamburgerVC
  }()

  init(viewModel: KWalletBalanceViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KWalletBalanceViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
  }

  // MARK: Set up UIs
  fileprivate func setupUI() {
    self.setupHamburgerMenu()
    self.setupWalletBalanceHeaderView()
    self.setupDisplayDataType()
    self.setupTokensBalanceCollectionView()
  }

  fileprivate func setupWalletBalanceHeaderView() {
    self.balanceTextLabel.text = "Balance".toBeLocalised()
    self.updateWalletBalanceUI()
    self.updateWalletInfoUI()
  }

  fileprivate func setupHamburgerMenu() {
    self.hamburgerMenu.hideMenu(animated: false)
  }

  fileprivate func setupDisplayDataType() {
    self.updateCurrencyDisplayType()
    self.searchTextField.delegate = self
  }

  fileprivate func setupTokensBalanceCollectionView() {
    // TODO:
    let nib = UINib(nibName: KWalletBalanceCollectionViewCell.className, bundle: nil)
    self.tokensBalanceCollectionView.register(
      nib,
      forCellWithReuseIdentifier: KWalletBalanceCollectionViewCell.cellID
    )
    self.tokensBalanceCollectionView.delegate = self
    self.tokensBalanceCollectionView.dataSource = self
    self.tokensBalanceCollectionView.reloadData()
  }

  // MARK: Update UIs
  fileprivate func updateWalletInfoUI() {
    self.walletNameLabel.text = self.viewModel.wallet.name
    self.view.layoutIfNeeded()
  }

  fileprivate func updateWalletBalanceUI() {
    self.balanceValueLabel.attributedText = self.viewModel.balanceDisplayAttributedString
    self.view.layoutIfNeeded()
  }

  fileprivate func updateCurrencyDisplayType() {
    self.usdButton.setTitleColor(self.viewModel.colorUSDButton, for: .normal)
    self.ethButton.setTitleColor(self.viewModel.colorETHButton, for: .normal)
    self.updateWalletBalanceUI()
    self.tokensBalanceCollectionView.reloadData()
    self.view.layoutIfNeeded()
  }

  // MARK: Actions handling
  @IBAction func menuButtonPressed(_ sender: Any) {
    self.hamburgerMenu.openMenu(animated: true)
  }

  @IBAction func marketButtonPressed(_ sender: Any) {
    self.delegate?.kWalletBalanceViewController(self, run: .openMarketView)
  }

  @IBAction func usdButtonPressed(_ sender: Any) {
    if self.viewModel.updateCurrencyType(.usd) {
      self.updateCurrencyDisplayType()
    }
  }

  @IBAction func ethButtonPressed(_ sender: Any) {
    if self.viewModel.updateCurrencyType(.eth) {
      self.updateCurrencyDisplayType()
    }
  }

  @IBAction func searchButtonPressed(_ sender: Any) {
    if !self.searchTextField.isFirstResponder { self.searchTextField.becomeFirstResponder() }
  }

  @IBAction func sortNameButtonPressed(_ sender: Any) {
    self.viewModel.updateTokenDisplayType(nameClicked: true)
    self.tokensBalanceCollectionView.reloadData()
  }

  @IBAction func sortBalanceButtonPressed(_ sender: Any) {
    self.viewModel.updateTokenDisplayType(nameClicked: false)
    self.tokensBalanceCollectionView.reloadData()
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    self.hamburgerMenu.gestureScreenEdgePanAction(sender)
  }
}

// MARK: Update from coordinator
extension KWalletBalanceViewController {
  func coordinatorUpdateSessionWithNewViewModel(_ viewModel: KWalletBalanceViewModel) {
    self.viewModel = viewModel
    self.updateWalletBalanceUI()
    self.updateWalletInfoUI()
    self.tokensBalanceCollectionView.reloadData()
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.wallet
    )
  }

  func coordinatorUpdateWalletObjects() {
    guard let currentWallet = KNWalletStorage.shared.get(forPrimaryKey: viewModel.wallet.address) else { return }
    self.viewModel.updateWalletObject(currentWallet)
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: currentWallet
    )
  }

  func coordinatorUpdateTokenObjects(_ tokenObjects: [TokenObject]) {
    if self.viewModel.updateTokenObjects(tokenObjects) {
      self.tokensBalanceCollectionView.reloadData()
    }
  }

  func coordinatorUpdateTokenBalances(_ balances: [String: Balance]) {
    if self.viewModel.updateTokenBalances(balances) {
      self.updateWalletBalanceUI()
      self.tokensBalanceCollectionView.reloadData()
    }
  }

  func coordinatorUpdateBalanceInETHAndUSD(ethBalance: BigInt, usdBalance: BigInt) {
    self.viewModel.updateBalanceInETHAndUSD(
      ethBalance: ethBalance,
      usdBalance: usdBalance
    )
    self.updateWalletBalanceUI()
    self.viewModel.exchangeRatesDataUpdated()
    self.tokensBalanceCollectionView.reloadData()
  }

  func coordinatorUpdatePendingTransactions(_ transactions: [KNTransaction]) {
    self.hamburgerMenu.update(transactions: transactions)
  }
}

// MARK: Hamburger menu delegation
extension KWalletBalanceViewController: KNBalanceTabHamburgerMenuViewControllerDelegate {
  func balanceTabHamburgerMenuViewController(_ controller: KNBalanceTabHamburgerMenuViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    self.delegate?.kWalletBalanceViewController(self, run: event)
  }
}

// MARK: Collection view delegate, datasource
extension KWalletBalanceViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let tokenObject = self.viewModel.tokenObject(for: indexPath.row)
    self.delegate?.kWalletBalanceViewController(self, run: .selectToken(token: tokenObject))
  }
}

extension KWalletBalanceViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KWalletBalanceCollectionViewCell.cellHeight
    )
  }
}

extension KWalletBalanceViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KWalletBalanceCollectionViewCell.cellID,
      for: indexPath) as! KWalletBalanceCollectionViewCell
    let row: Int = indexPath.row

    // Data for cell
    let tokenObject: TokenObject = self.viewModel.tokenObject(for: row)
    let trackerRate: KNTrackerRate? = self.viewModel.trackerRate(for: row)
    let balance: Balance? = self.viewModel.balance(for: tokenObject)
//    let icon: String? = self.viewModel.iconName(for: tokenObject)

    let cellModel = KWalletBalanceCollectionViewCellModel(
      token: tokenObject,
      trackerRate: trackerRate,
      balance: balance,
      currencyType: self.viewModel.currencyType,
      index: indexPath.row
    )
    cell.updateCellView(with: cellModel)
    return cell
  }
}

extension KWalletBalanceViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if textField == self.searchTextField {
      self.searchAmountTextFieldChanged()
    }
    return true
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.searchTextField {
      self.searchAmountTextFieldChanged()
    }
    return false
  }

  fileprivate func searchAmountTextFieldChanged() {
    self.viewModel.updateSearchText(self.searchTextField.text ?? "")
    self.tokensBalanceCollectionView.reloadData()
  }
}
