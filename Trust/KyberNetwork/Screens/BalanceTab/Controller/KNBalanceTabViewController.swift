// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNBalanceTabViewControllerDelegate: class {
  func balanceTabDidSelectQRCodeButton(in controller: KNBalanceTabViewController)
  func balanceTabDidSelectWalletListButton(in controller: KNBalanceTabViewController)
  func balanceTabDidSelectAddTokenButton(in controller: KNBalanceTabViewController)
  func balanceTabDidSelectExchange(for tokenObject: TokenObject, in controller: KNBalanceTabViewController)
  func balanceTabDidSelectSend(for tokenObject: TokenObject, in controller: KNBalanceTabViewController)
}

class KNBalanceTabViewController: KNBaseViewController {

  @IBOutlet weak var balanceTopView: UIView!
  @IBOutlet weak var walletIconImageView: UIImageView!
  @IBOutlet weak var walletAddressLabel: UILabel!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var walletBalanceButton: UIButton!

  @IBOutlet weak var balanceButtonControlView: UIView!
  @IBOutlet weak var filterSortButton: UIButton!
  @IBOutlet weak var addTokenButton: UIButton!

  @IBOutlet weak var tokensBalanceCollectionView: UICollectionView!

  fileprivate var fakeFilterSortTextField: UITextField = UITextField(frame: CGRect.zero)
  fileprivate var filterSortPickerView: UIPickerView = UIPickerView(frame: CGRect.zero)
  fileprivate var selectedFilterSortString: String = ""

  weak var delegate: KNBalanceTabViewControllerDelegate?
  fileprivate var viewModel: KNBalanceTabViewModel

  lazy var hamburgerMenu: KNBalanceTabHamburgerMenuViewController = {
    // TODO: List of wallet objects
    let viewModel = KNBalanceTabHamburgerMenuViewModel(walletObjects: [self.viewModel.wallet], currentWallet: self.viewModel.wallet)
    let hamburgerVC = KNBalanceTabHamburgerMenuViewController(viewModel: viewModel)
    hamburgerVC.view.frame = self.view.bounds
    self.view.addSubview(hamburgerVC.view)
    self.addChildViewController(hamburgerVC)
    hamburgerVC.didMove(toParentViewController: self)
    hamburgerVC.delegate = self
    return hamburgerVC
  }()

  init(with viewModel: KNBalanceTabViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNBalanceTabViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let colors: [UIColor] = [UIColor(hex: "20aba2"), UIColor(hex: "3bcaa0")]
    self.balanceTopView.applyVerticalGradient(with: colors)
  }

  fileprivate func setupUI() {
    self.setupBalanceTopView()
    self.setupBalanceButtonControlView()
    self.setupTokensBalanceCollectionView()
    self.setupHamburgerMenu()
  }

  fileprivate func setupBalanceTopView() {
    self.balanceTopView.alpha = 0.72

    self.walletIconImageView.rounded(
      color: .clear,
      width: 0,
      radius: self.walletIconImageView.frame.width / 2.0
    )

    self.walletBalanceButton.semanticContentAttribute = .forceRightToLeft
    self.walletBalanceButton.setTitle("0 USD", for: .normal)

    self.updateWalletUI()
  }

  fileprivate func setupBalanceButtonControlView() {
    self.filterSortButton.semanticContentAttribute = .forceRightToLeft
    self.addTokenButton.semanticContentAttribute = .forceRightToLeft
    self.addTokenButton.setTitle(self.viewModel.addTokenButtonTitle, for: .normal)

    // MARK: Create picker view for selecting displaying data
    self.filterSortPickerView = {
      let picker = UIPickerView(frame: CGRect.zero)
      picker.showsSelectionIndicator = true
      picker.dataSource = self
      picker.delegate = self
      return picker
    }()
    self.view.addSubview(self.fakeFilterSortTextField)
    self.fakeFilterSortTextField.inputView = self.filterSortPickerView

    let toolBar: UIToolbar = {
      let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
      let toolBar = UIToolbar(frame: frame)
      toolBar.barStyle = .default
      let doneBtn = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(self.displayDataTypePickerViewDonePressed(_:))
      )
      let flexibleSpaceBtn = UIBarButtonItem(
        barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
        target: nil,
        action: nil
      )
      doneBtn.tintColor = UIColor(hex: "505352")
      let cancelBtn = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(self.displayDataTypePickerViewCancelPressed(_:))
      )
      cancelBtn.tintColor = UIColor(hex: "505352")
      toolBar.setItems([cancelBtn, flexibleSpaceBtn, doneBtn], animated: false)
      return toolBar
    }()
    self.fakeFilterSortTextField.inputAccessoryView = toolBar

    self.updateFilterSortTokenButton()
  }

  fileprivate func setupTokensBalanceCollectionView() {
    let nib = UINib(nibName: KNTokenBalanceCollectionViewCell.className, bundle: nil)
    self.tokensBalanceCollectionView.register(
      nib,
      forCellWithReuseIdentifier: KNTokenBalanceCollectionViewCell.cellID
    )
    self.tokensBalanceCollectionView.delegate = self
    self.tokensBalanceCollectionView.dataSource = self
    self.tokensBalanceCollectionView.reloadData()
  }

  fileprivate func setupHamburgerMenu() {
    self.hamburgerMenu.hideMenu(animated: false)
  }

  @IBAction func qrcodeButtonPressed(_ sender: Any) {
    self.delegate?.balanceTabDidSelectQRCodeButton(in: self)
  }

  @IBAction func walletListButtonPressed(_ sender: Any) {
    self.hamburgerMenu.openMenu(animated: true)
  }

  @IBAction func walletBalanceButtonPressed(_ sender: Any) {
    // Change display balance currency (ETH and USD)
    self.viewModel.updateBalanceDisplayType()
    self.updateBalanceUI()
  }

  @IBAction func tokensDisplayTypeButtonPressed(_ sender: Any) {
    self.selectedFilterSortString = self.viewModel.filterSortButtonTitle
    self.fakeFilterSortTextField.becomeFirstResponder()
    if let index = self.viewModel.listPickerData.index(of: self.selectedFilterSortString) {
      self.filterSortPickerView.selectRow(index, inComponent: 0, animated: true)
    }
  }

  @IBAction func addTokenButtonPressed(_ sender: Any) {
    self.delegate?.balanceTabDidSelectAddTokenButton(in: self)
  }

  @objc func displayDataTypePickerViewDonePressed(_ sender: Any?) {
    self.fakeFilterSortTextField.resignFirstResponder()
    if self.viewModel.updateTokensDisplayType(self.selectedFilterSortString) {
      self.updateFilterSortTokenButton()
      self.tokensBalanceCollectionView.reloadData()
    }
  }

  @objc func displayDataTypePickerViewCancelPressed(_ sender: Any?) {
    self.fakeFilterSortTextField.resignFirstResponder()
  }
}

// MARK: Update from coordinator
extension KNBalanceTabViewController {
  func coordinatorUpdateSessionWithNewViewModel(_ viewModel: KNBalanceTabViewModel) {
    self.viewModel = viewModel
    self.updateWalletUI()
    self.updateBalanceUI()
    self.updateFilterSortTokenButton()
    self.tokensBalanceCollectionView.reloadData()
    // TODO: List of wallet objects
    self.hamburgerMenu.update(walletObjects: [self.viewModel.wallet], currentWallet: self.viewModel.wallet)
  }

  func coordinatorUpdateTokenObjects(_ tokenObjects: [TokenObject]) {
    if self.viewModel.updateTokenObjects(tokenObjects) {
      self.tokensBalanceCollectionView.reloadData()
    }
  }

  func coordinatorUpdateTokenBalances(_ balances: [String: Balance]) {
    if self.viewModel.updateTokenBalances(balances) {
      self.updateBalanceUI()
      self.tokensBalanceCollectionView.reloadData()
    }
  }

  func coordinatorUpdateBalanceInETHAndUSD(ethBalance: BigInt, usdBalance: BigInt) {
    self.viewModel.updateBalanceInETHAndUSD(
      ethBalance: ethBalance,
      usdBalance: usdBalance
    )
    self.updateBalanceUI()
  }

  func coordinatorCoinTickerDidUpdate() {
    self.viewModel.coinTickersDidUpdate()
    self.tokensBalanceCollectionView.reloadData()
  }
}

// MARK: Update UIs
extension KNBalanceTabViewController {
  fileprivate func updateWalletUI() {
    self.walletIconImageView.image = UIImage(named: self.viewModel.walletIconName)
    self.walletAddressLabel.text = self.viewModel.walletAddressDisplayedText
    self.walletNameLabel.text = self.viewModel.walletNameDisplayedText
    self.view.layoutIfNeeded()
  }

  fileprivate func updateBalanceUI() {
    UIView.transition(
      with: self.walletBalanceButton,
      duration: 0.3,
      options: UIViewAnimationOptions.curveLinear,
      animations: {
        self.walletBalanceButton.setTitle(self.viewModel.balanceDisplayText, for: .normal)
        self.view.layoutIfNeeded()
    }, completion: nil)
  }

  fileprivate func updateFilterSortTokenButton() {
    UIView.transition(
      with: self.filterSortButton,
      duration: 0.3,
      options: UIViewAnimationOptions.transitionFlipFromTop,
      animations: {
        self.filterSortButton.setTitle(self.viewModel.filterSortButtonTitle, for: .normal)
        self.view.layoutIfNeeded()
    }, completion: nil)
  }
}

extension KNBalanceTabViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let tokenObject = self.viewModel.tokenObject(for: indexPath.row)
    guard let expandedIndex = self.viewModel.expandedTokenIndex() else {
      // no expanded, expaned the selected row
      self.viewModel.expandedToken = tokenObject.contract
      collectionView.reloadItems(at: [indexPath])
      return
    }
    if expandedIndex == indexPath.row {
      // tap to expanded row, should reset this row to normal
      self.viewModel.expandedToken = ""
      collectionView.reloadItems(at: [indexPath])
    } else {
      self.viewModel.expandedToken = tokenObject.contract
      let oldIndexPath = IndexPath(row: expandedIndex, section: 0)
      collectionView.reloadItems(at: [oldIndexPath, indexPath])
    }
  }
}

extension KNBalanceTabViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 8
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNTokenBalanceCollectionViewCell.cellHeight
    )
  }
}

extension KNBalanceTabViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KNTokenBalanceCollectionViewCell.cellID,
      for: indexPath) as! KNTokenBalanceCollectionViewCell
    let row: Int = indexPath.row

    // Data for cell
    let tokenObject: TokenObject = self.viewModel.tokenObject(for: row)
    let coinTicker: KNCoinTicker? = self.viewModel.coinTicker(for: row)
    let balance: Balance? = self.viewModel.balance(for: tokenObject)
    let icon: String? = self.viewModel.iconName(for: tokenObject)

    let cellModel = KNTokenBalanceCollectionViewCellModel(
      token: tokenObject,
      icon: icon,
      coinTicker: coinTicker,
      balance: balance
    )
    cell.updateCell(
      with: cellModel,
      isSelected: self.viewModel.expandedToken == tokenObject.contract
    )
    cell.delegate = self
    return cell
  }
}

extension KNBalanceTabViewController: UIPickerViewDelegate {
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    self.selectedFilterSortString = self.viewModel.listPickerData[row]
  }
}

extension KNBalanceTabViewController: UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return self.viewModel.listPickerData.count
  }

  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 32
  }

  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "505352"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17),
    ]
    return NSAttributedString(
      string: self.viewModel.listPickerData[row],
      attributes: attributes
    )
  }
}

extension KNBalanceTabViewController: KNTokenBalanceCollectionViewCellDelegate {
  func tokenBalanceCollectionViewCellSendButtonPressed(for tokenObject: TokenObject) {
    self.delegate?.balanceTabDidSelectSend(for: tokenObject, in: self)
  }

  func tokenBalanceCollectionViewCellExchangeButtonPressed(for tokenObject: TokenObject) {
    self.delegate?.balanceTabDidSelectExchange(for: tokenObject, in: self)
  }
}

extension KNBalanceTabViewController: KNBalanceTabHamburgerMenuViewControllerDelegate {
  func balanceTabHamburgerMenuDidSelectSettings(sender: KNBalanceTabHamburgerMenuViewController) {
    //TODO: Implement it
  }

  func balanceTabHamburgerMenuDidSelectManageWallet(sender: KNBalanceTabHamburgerMenuViewController) {
    //TODO: Implement it
  }

  func balanceTabHamburgerMenuDidSelect(walelt: KNWalletObject, sender: KNBalanceTabHamburgerMenuViewController) {
    //TODO: Implement it
  }
}
