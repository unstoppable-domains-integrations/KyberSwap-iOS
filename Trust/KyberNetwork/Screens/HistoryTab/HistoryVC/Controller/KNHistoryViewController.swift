// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNHistoryViewControllerDelegate: class {
  func historyViewControllerDidSelectTransaction(_ transaction: KNHistoryTransaction)
  func historyViewControllerDidSelectTokenTransaction(_ transaction: KNTokenTransaction)
  func historyViewControllerDidClickExit()
}

class KNHistoryViewController: KNBaseViewController {

  fileprivate weak var delegate: KNHistoryViewControllerDelegate?
  fileprivate let tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens

  fileprivate var trackerData: [String: [KNHistoryTransaction]] = [:]
  fileprivate var trackerHeaders: [String] = []

  fileprivate var tokensTxData: [String: [KNTokenTransaction]] = [:]
  fileprivate var tokensTxHeaders: [String] = []

  fileprivate var ownerAddress: String = ""

  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var noHistoryTransactionsLabel: UILabel!
  @IBOutlet weak var transactionCollectionView: UICollectionView!

  fileprivate var hasUpdatedData: Bool = false
  fileprivate var isShowingLoading: Bool = false

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

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !self.hasUpdatedData && !self.isShowingLoading {
      self.isShowingLoading = true
      self.displayLoading(text: "Loading Transactions...", animated: true)
    }
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
    self.segmentedControl.rounded(color: .clear, width: 0, radius: 5.0)
    let nib = UINib(nibName: KNTransactionCollectionViewCell.className, bundle: nil)
    self.transactionCollectionView.register(nib, forCellWithReuseIdentifier: KNTransactionCollectionViewCell.cellID)
    let headerNib = UINib(nibName: KNTransactionCollectionReusableView.className, bundle: nil)
    self.transactionCollectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: KNTransactionCollectionReusableView.viewID)
    self.transactionCollectionView.delegate = self
    self.transactionCollectionView.dataSource = self

    self.noHistoryTransactionsLabel.text = "No history transactions".toBeLocalised()
    self.noHistoryTransactionsLabel.isHidden = true
  }

  fileprivate func updateUIWhenDataDidChange() {
    let headers = self.segmentedControl.selectedSegmentIndex == 0 ? self.trackerHeaders : self.tokensTxHeaders
    if headers.isEmpty {
      self.noHistoryTransactionsLabel.isHidden = false
      self.transactionCollectionView.isHidden = true
    } else {
      self.noHistoryTransactionsLabel.isHidden = true
      self.transactionCollectionView.isHidden = false
    }
    self.transactionCollectionView.reloadData()
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.historyViewControllerDidClickExit()
  }

  @IBAction func segmentedControlValueDidChange(_ sender: UISegmentedControl) {
    self.updateUIWhenDataDidChange()
  }
}

extension KNHistoryViewController {
  func coordinatorUpdateHistoryTransactions(
    data: [String: [KNHistoryTransaction]],
    dates: [String],
    ownerAddress: String
    ) {
    self.hasUpdatedData = true
    if self.isShowingLoading { self.hideLoading() }
    self.trackerData = data
    self.trackerHeaders = dates
    self.ownerAddress = ownerAddress
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdateTokenTransactions(
    data: [String: [KNTokenTransaction]],
    dates: [String],
    ownerAddress: String
    ) {
    self.tokensTxData = data
    self.tokensTxHeaders = dates
    self.ownerAddress = ownerAddress
    self.updateUIWhenDataDidChange()
  }
}

extension KNHistoryViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if self.segmentedControl.selectedSegmentIndex == 0 {
      guard let transactions = self.trackerData[self.trackerHeaders[indexPath.section]] else { return }
      self.delegate?.historyViewControllerDidSelectTransaction(transactions[indexPath.row])
    } else {
      guard let transactions = self.tokensTxData[self.tokensTxHeaders[indexPath.section]] else { return }
      self.delegate?.historyViewControllerDidSelectTokenTransaction(transactions[indexPath.row])
    }
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
    if self.segmentedControl.selectedSegmentIndex == 0 {
      return self.trackerHeaders.count
    }
    return self.tokensTxHeaders.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if self.segmentedControl.selectedSegmentIndex == 0 {
      return self.trackerData[self.trackerHeaders[section]]?.count ?? 0
    }
    return self.tokensTxData[self.tokensTxHeaders[section]]?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNTransactionCollectionViewCell.cellID, for: indexPath) as! KNTransactionCollectionViewCell
    if self.segmentedControl.selectedSegmentIndex == 0 {
      guard let trans = self.trackerData[self.trackerHeaders[indexPath.section]] else { return cell }
      let tran = trans[indexPath.row]
      cell.updateCell(with: tran, tokens: self.tokens, ownerAddress: self.ownerAddress)
    } else {
      guard let trans = self.tokensTxData[self.tokensTxHeaders[indexPath.section]] else { return cell }
      let tran = trans[indexPath.row]
      cell.updateCell(with: tran, ownerAddress: self.ownerAddress)
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KNTransactionCollectionReusableView.viewID, for: indexPath) as! KNTransactionCollectionReusableView
      let data: String = {
        if self.segmentedControl.selectedSegmentIndex == 0 {
          return self.trackerHeaders[indexPath.section]
        } else {
          return self.tokensTxHeaders[indexPath.section]
        }
      }()
      headerView.updateView(with: data)
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}
