// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KMarketsViewEvent {
  case close
  case selectToken(token: TokenObject)
}

protocol KMarketViewControllerDelegate: class {
  func kMarketViewController(_ controller: KMarketViewController, run event: KMarketsViewEvent)
}

class KMarketViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var kyberListedButton: UIButton!
  @IBOutlet weak var otherButton: UIButton!
  @IBOutlet weak var searchTextField: UITextField!

  @IBOutlet weak var tokensCollectionView: UICollectionView!

  fileprivate var viewModel: KMarketsViewModel
  weak var delegate: KMarketViewControllerDelegate?

  init(viewModel: KMarketsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KMarketViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUIs()
  }

  // MARK: Set up UIs
  fileprivate func setupUIs() {
    self.view.backgroundColor = KNAppStyleType.current.mainBackgroundColor
    self.headerContainerView.backgroundColor = KNAppStyleType.current.walletFlowHeaderColor
    self.setupDisplayKyberListed()
    self.setupDisplayTypeView()
    self.setupTokensCollectionView()
  }

  fileprivate func setupDisplayKyberListed() {
    self.searchTextField.delegate = self
    self.updateDisplayKyberListedData()
  }

  fileprivate func setupDisplayTypeView() {
  }

  fileprivate func setupTokensCollectionView() {
    let nib = UINib(nibName: KMarketCollectionViewCell.className, bundle: nil)
    self.tokensCollectionView.register(
      nib,
      forCellWithReuseIdentifier: KMarketCollectionViewCell.cellID
    )
    self.tokensCollectionView.delegate = self
    self.tokensCollectionView.dataSource = self
    self.tokensCollectionView.reloadData()
  }

  // MARK: Update UIs
  fileprivate func updateDisplayKyberListedData() {
    self.kyberListedButton.setTitleColor(self.viewModel.colorKyberListedButton, for: .normal)
    self.otherButton.setTitleColor(self.viewModel.colorOthersButton, for: .normal)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kMarketViewController(self, run: .close)
  }

  // MARK: Actions handling
  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.kMarketViewController(self, run: .close)
    }
  }

  @IBAction func kyberListedButtonPressed(_ sender: Any) {
    self.viewModel.updateDisplayKyberList(true)
    self.updateDisplayKyberListedData()
    self.tokensCollectionView.reloadData()
  }

  @IBAction func othersButtonPressed(_ sender: Any) {
    self.viewModel.updateDisplayKyberList(false)
    self.updateDisplayKyberListedData()
    self.tokensCollectionView.reloadData()
  }

  @IBAction func searchButtonPressed(_ sender: Any) {
    self.searchTextField.becomeFirstResponder()
  }

  @IBAction func sortByNameButtonPressed(_ sender: Any) {
    self.viewModel.updateTokenDisplayType(positionClicked: 1)
    self.tokensCollectionView.reloadData()
  }

  @IBAction func sortByPriceButtonPressed(_ sender: Any) {
    self.viewModel.updateTokenDisplayType(positionClicked: 2)
    self.tokensCollectionView.reloadData()
  }

  @IBAction func sortByChangeButtonPressed(_ sender: Any) {
    self.viewModel.updateTokenDisplayType(positionClicked: 3)
    self.tokensCollectionView.reloadData()
  }
}

// MARK: Update from coordinator
extension KMarketViewController {
  func coordinatorUpdateSessionWithNewViewModel(_ viewModel: KMarketsViewModel) {
    self.viewModel = viewModel
    self.tokensCollectionView.reloadData()
  }

  func coordinatorUpdateTokenObjects(_ tokenObjects: [TokenObject]) {
    if self.viewModel.updateTokenObjects(tokenObjects) {
      self.tokensCollectionView.reloadData()
    }
  }

  func coordinatorUpdateTrackerRate() {
    self.viewModel.exchangeRatesDataUpdated()
    self.tokensCollectionView.reloadData()
  }
}

// MARK: Collection view delegate, datasource
extension KMarketViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let tokenObject = self.viewModel.tokenObject(for: indexPath.row)
    self.delegate?.kMarketViewController(self, run: .selectToken(token: tokenObject))
  }
}

extension KMarketViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KMarketCollectionViewCell.cellHeight
    )
  }
}

extension KMarketViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KMarketCollectionViewCell.cellID,
      for: indexPath) as! KMarketCollectionViewCell
    let row: Int = indexPath.row

    // Data for cell
    let tokenObject: TokenObject = self.viewModel.tokenObject(for: row)
    let trackerRate: KNTrackerRate? = self.viewModel.trackerRate(for: row)

    let cellModel = KMarketCollectionViewCellModel(
      token: tokenObject,
      trackerRate: trackerRate,
      currencyType: self.viewModel.currencyType,
      index: indexPath.row
    )
    cell.updateCellView(with: cellModel)
    return cell
  }
}

extension KMarketViewController: UITextFieldDelegate {
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
    self.tokensCollectionView.reloadData()
  }
}
