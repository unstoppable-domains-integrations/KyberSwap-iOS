// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KWalletBalanceViewEvent {
  case openQRCode
  case selectToken(token: TokenObject)
  case buy(token: TokenObject)
  case sell(token: TokenObject)
  case send(token: TokenObject)
  case openMarketView
  case receiveToken
}

protocol KWalletBalanceViewControllerDelegate: class {
  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run event: KWalletBalanceViewEvent)
  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run menuEvent: KNBalanceTabHamburgerMenuViewEvent)
}

class KWalletBalanceViewController: KNBaseViewController {

  fileprivate var isViewSetup: Bool = false

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var walletDataView: UIView!
  @IBOutlet weak var balanceTextLabel: UILabel!
  @IBOutlet weak var balanceValueLabel: UILabel!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var emptyStateView: UIView!
  @IBOutlet weak var emptyBalanceTextLabel: UILabel!
  @IBOutlet weak var receiveTokenButton: UIButton!

  @IBOutlet weak var kyberListButton: UIButton!
  @IBOutlet weak var otherButton: UIButton!
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var currencyButton: UIButton!

  @IBOutlet weak var tokensBalanceTableView: UITableView!

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
    self.headerContainerView.backgroundColor = self.viewModel.headerBackgroundColor
  }

  // MARK: Set up UIs
  fileprivate func setupUI() {
    self.setupHamburgerMenu()
    self.setupWalletBalanceHeaderView()
    self.setupDisplayDataType()
    self.setupTokensBalanceTableView()
  }

  fileprivate func setupWalletBalanceHeaderView() {
    self.balanceTextLabel.text = "Balance".toBeLocalised()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.openQRCodeViewPressed(_:)))
    self.walletDataView.addGestureRecognizer(tapGesture)
    self.updateWalletBalanceUI()
    self.updateWalletInfoUI()
  }

  fileprivate func setupHamburgerMenu() {
    self.hamburgerMenu.hideMenu(animated: false)
  }

  fileprivate func setupDisplayDataType() {
    self.updateDisplayedDataType()
    self.searchTextField.delegate = self
  }

  fileprivate func setupTokensBalanceTableView() {
    let nib = UINib(nibName: KNBalanceTokenTableViewCell.className, bundle: nil)
    self.tokensBalanceTableView.register(
      nib,
      forCellReuseIdentifier: KNBalanceTokenTableViewCell.kCellID
    )
    self.tokensBalanceTableView.delegate = self
    self.tokensBalanceTableView.dataSource = self
    self.tokensBalanceTableView.rowHeight = KNBalanceTokenTableViewCell.kCellHeight
    self.tokensBalanceTableView.reloadData()

    self.emptyBalanceTextLabel.text = self.viewModel.textBalanceIsEmpty
    let style = KNAppStyleType.current
    self.receiveTokenButton.backgroundColor = style.walletFlowHeaderColor
    self.receiveTokenButton.rounded(radius: style.buttonRadius(for: self.receiveTokenButton.frame.height))
  }

  // MARK: Update UIs
  fileprivate func updateWalletInfoUI() {
    self.walletNameLabel.text = self.viewModel.wallet.name
    self.view.layoutIfNeeded()
  }

  fileprivate func updateWalletBalanceUI() {
    self.balanceValueLabel.attributedText = self.viewModel.balanceDisplayAttributedString
    self.tokensBalanceTableView.isHidden = !self.viewModel.hasTokens
    self.emptyStateView.isHidden = self.viewModel.hasTokens
    self.view.layoutIfNeeded()
  }

  fileprivate func updateDisplayedDataType() {
    self.currencyButton.semanticContentAttribute = .forceRightToLeft
    self.currencyButton.setTitle(self.viewModel.currencyType.rawValue, for: .normal)
    self.kyberListButton.setTitleColor(self.viewModel.colorKyberListedButton, for: .normal)
    self.otherButton.setTitleColor(self.viewModel.colorOthersButton, for: .normal)
    self.updateWalletBalanceUI()
    self.tokensBalanceTableView.reloadData()
    self.view.layoutIfNeeded()
  }

  // MARK: Actions handling

  @objc func openQRCodeViewPressed(_ sender: Any) {
    self.delegate?.kWalletBalanceViewController(self, run: .openQRCode)
  }

  @IBAction func menuButtonPressed(_ sender: Any) {
    self.hamburgerMenu.openMenu(animated: true)
  }

  @IBAction func marketButtonPressed(_ sender: Any) {
    self.delegate?.kWalletBalanceViewController(self, run: .openMarketView)
  }

  @IBAction func kyberListButtonPressed(_ sender: Any) {
    if self.viewModel.updateDisplayKyberList(true) {
      self.updateDisplayedDataType()
    }
  }

  @IBAction func otherButtonPressed(_ sender: Any) {
    if self.viewModel.updateDisplayKyberList(false) {
      self.updateDisplayedDataType()
    }
  }

  @IBAction func searchButtonPressed(_ sender: Any) {
    if !self.searchTextField.isFirstResponder { self.searchTextField.becomeFirstResponder() }
  }

  @IBAction func sortNameButtonPressed(_ sender: Any) {
    self.viewModel.updateTokenDisplayType(positionClicked: 1)
    self.tokensBalanceTableView.reloadData()
  }

  @IBAction func changeButtonPressed(_ sender: Any) {
    self.viewModel.updateTokenDisplayType(positionClicked: 3)
    self.tokensBalanceTableView.reloadData()
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    self.hamburgerMenu.gestureScreenEdgePanAction(sender)
  }

  @IBAction func receiveTokenButtonPressed(_ sender: Any) {
    self.delegate?.kWalletBalanceViewController(self, run: .receiveToken)
  }

  @IBAction func currencyButtonPressed(_ sender: Any) {
    let newType: KWalletCurrencyType = self.viewModel.currencyType == .usd ? .eth : .usd
    _ = self.viewModel.updateCurrencyType(newType)
    self.updateDisplayedDataType()
  }
}

// MARK: Update from coordinator
extension KWalletBalanceViewController {
  func coordinatorUpdateSessionWithNewViewModel(_ viewModel: KWalletBalanceViewModel) {
    self.viewModel = viewModel
    self.updateWalletBalanceUI()
    self.updateWalletInfoUI()
    self.tokensBalanceTableView.reloadData()
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
      self.updateWalletBalanceUI()
      self.tokensBalanceTableView.reloadData()
    }
  }

  func coordinatorUpdateTokenBalances(_ balances: [String: Balance]) {
    if self.viewModel.updateTokenBalances(balances) {
      self.updateWalletBalanceUI()
      self.tokensBalanceTableView.reloadData()
    }
  }

  func coordinatorUpdateBalanceInETHAndUSD(ethBalance: BigInt, usdBalance: BigInt) {
    self.viewModel.updateBalanceInETHAndUSD(
      ethBalance: ethBalance,
      usdBalance: usdBalance
    )
    self.updateWalletBalanceUI()
    self.viewModel.exchangeRatesDataUpdated()
    self.tokensBalanceTableView.reloadData()
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

// MARK: Table view delegate, datasource
extension KWalletBalanceViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let tokenObject = self.viewModel.tokenObject(for: indexPath.row)
    self.delegate?.kWalletBalanceViewController(self, run: .selectToken(token: tokenObject))
  }
}

extension KWalletBalanceViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: KNBalanceTokenTableViewCell.kCellID,
      for: indexPath
    ) as! KNBalanceTokenTableViewCell
    let row: Int = indexPath.row

    // Data for cell
    let tokenObject: TokenObject = self.viewModel.tokenObject(for: row)
    let trackerRate: KNTrackerRate? = self.viewModel.trackerRate(for: row)
    let balance: Balance? = self.viewModel.balance(for: tokenObject)

    let cellModel = KNBalanceTokenTableViewCellModel(
      token: tokenObject,
      trackerRate: trackerRate,
      balance: balance,
      currencyType: self.viewModel.currencyType,
      index: indexPath.row
    )
    cell.updateCellView(with: cellModel)
    return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let tokenObject = self.viewModel.tokenObject(for: indexPath.row)
    let sendAction = UITableViewRowAction(style: .default, title: "Send") { _, _ in
      self.delegate?.kWalletBalanceViewController(self, run: .send(token: tokenObject))
    }
    sendAction.backgroundColor = UIColor.Kyber.merigold
    let sellAction = UITableViewRowAction(style: .default, title: "Sell") { _, _ in
      self.delegate?.kWalletBalanceViewController(self, run: .sell(token: tokenObject))
    }
    sellAction.backgroundColor = UIColor.Kyber.blueGreen
    let buyAction = UITableViewRowAction(style: .default, title: "Buy") { _, _ in
      self.delegate?.kWalletBalanceViewController(self, run: .buy(token: tokenObject))
    }
    buyAction.backgroundColor = UIColor.Kyber.shamrock
    return tokenObject.isSupported ? [sendAction, sellAction, buyAction] : [sendAction]
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
    self.tokensBalanceTableView.reloadData()
  }
}
