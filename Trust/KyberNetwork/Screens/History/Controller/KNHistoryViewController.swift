// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNHistoryViewControllerDelegate: class {
  func historyViewControllerDidSelectTransaction(_ transaction: KNHistoryTransaction)
  func historyViewControllerDidClickExit()
}

class KNHistoryViewController: KNBaseViewController {

  fileprivate weak var delegate: KNHistoryViewControllerDelegate?
  fileprivate let tokens: [KNToken] = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()

  fileprivate var sectionsData: [String: [KNHistoryTransaction]] = [:]
  fileprivate var sectionHeaders: [String] = []
  @IBOutlet weak var transactionCollectionView: UICollectionView!

  init(delegate: KNHistoryViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNHistoryViewController.className, bundle: nil)
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
    self.setupCollectionView()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = "History".toBeLocalised()
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .plain, target: self, action: #selector(self.exitButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
  }

  fileprivate func setupCollectionView() {
    let nib = UINib(nibName: KNTransactionCollectionViewCell.className, bundle: nil)
    self.transactionCollectionView.register(nib, forCellWithReuseIdentifier: KNTransactionCollectionViewCell.cellID)
    let headerNib = UINib(nibName: KNTransactionCollectionReusableView.className, bundle: nil)
    self.transactionCollectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: KNTransactionCollectionReusableView.viewID)
    self.transactionCollectionView.delegate = self
    self.transactionCollectionView.dataSource = self
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.historyViewControllerDidClickExit()
  }
}

extension KNHistoryViewController {
  func coordinatorUpdateHistoryTransactions(_ data: [String: [KNHistoryTransaction]], dates: [String]) {
    self.sectionsData = data
    self.sectionHeaders = dates
    self.transactionCollectionView.reloadData()
  }
}

extension KNHistoryViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let transactions = self.sectionsData[self.sectionHeaders[indexPath.section]] else { return }
    self.delegate?.historyViewControllerDidSelectTransaction(transactions[indexPath.row])
  }
}

extension KNHistoryViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 10
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNTransactionCollectionViewCell.cellHeight
    )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: 32
    )
  }
}

extension KNHistoryViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.sectionHeaders.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.sectionsData[self.sectionHeaders[section]]?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNTransactionCollectionViewCell.cellID, for: indexPath) as! KNTransactionCollectionViewCell
    guard let trans = self.sectionsData[self.sectionHeaders[indexPath.section]] else { return cell }
    let tran = trans[indexPath.row]
    cell.updateCell(with: tran, tokens: self.tokens)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KNTransactionCollectionReusableView.viewID, for: indexPath) as! KNTransactionCollectionReusableView
      headerView.updateView(with: self.sectionHeaders[indexPath.section])
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}
