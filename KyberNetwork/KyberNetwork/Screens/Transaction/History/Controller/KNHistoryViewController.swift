// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Crashlytics

enum KNHistoryViewEvent {
  case selectTransaction(transaction: Transaction)
  case dismiss
}

protocol KNHistoryViewControllerDelegate: class {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent)
}

struct KNHistoryViewModel {
  fileprivate(set) var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens

  fileprivate(set) var completedTxData: [String: [Transaction]] = [:]
  fileprivate(set) var completedTxHeaders: [String] = []

  fileprivate(set) var pendingTxData: [String: [Transaction]] = [:]
  fileprivate(set) var pendingTxHeaders: [String] = []

  fileprivate(set) var currentWallet: KNWalletObject

  fileprivate(set) var isShowingPending: Bool = true

  init(
    tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens,
    completedTxData: [String: [Transaction]],
    completedTxHeaders: [String],
    pendingTxData: [String: [Transaction]],
    pendingTxHeaders: [String],
    currentWallet: KNWalletObject
    ) {
    self.tokens = tokens
    self.completedTxData = completedTxData
    self.completedTxHeaders = completedTxHeaders
    self.pendingTxData = pendingTxData
    self.pendingTxHeaders = pendingTxHeaders
    self.currentWallet = currentWallet
    self.isShowingPending = true
  }

  mutating func updateIsShowingPending(_ isShowingPending: Bool) {
    self.isShowingPending = isShowingPending
  }

  mutating func update(tokens: [TokenObject]) {
    self.tokens = tokens
  }

  mutating func update(pendingTxData: [String: [Transaction]], pendingTxHeaders: [String]) {
    self.pendingTxData = pendingTxData
    self.pendingTxHeaders = pendingTxHeaders
  }

  mutating func update(completedTxData: [String: [Transaction]], completedTxHeaders: [String]) {
    self.completedTxData = completedTxData
    self.completedTxHeaders = completedTxHeaders
  }

  mutating func updateCurrentWallet(_ currentWallet: KNWalletObject) {
    self.currentWallet = currentWallet
  }

  var isEmptyStateHidden: Bool {
    if self.isShowingPending { return !self.pendingTxHeaders.isEmpty }
    return !self.completedTxHeaders.isEmpty
  }

  var emptyStateIconName: String {
    return self.isShowingPending ? "no_pending_tx_icon" : "no_mined_tx_icon"
  }

  var emptyStateDescLabelString: String {
    let noPendingTx = NSLocalizedString("you.do.not.have.any.pending.transactions", value: "You do not have any pending transactions.", comment: "")
    let noCompletedTx = NSLocalizedString("you.do.not.have.any.completed.transactions", value: "You do not have any completed transactions.", comment: "")
    return self.isShowingPending ? noPendingTx : noCompletedTx
  }

  var isRateMightChangeHidden: Bool {
    return !(self.isShowingPending && !self.pendingTxHeaders.isEmpty)
  }

  var transactionCollectionViewBottomPaddingConstraint: CGFloat {
    return self.isRateMightChangeHidden ? 0.0 : 192.0
  }

  var isTransactionCollectionViewHidden: Bool {
    return !self.isEmptyStateHidden
  }

  var numberSections: Int {
    if self.isShowingPending { return self.pendingTxHeaders.count }
    return self.completedTxHeaders.count
  }

  func header(for section: Int) -> String {
    let header: String = {
      if self.isShowingPending { return self.pendingTxHeaders[section] }
      return self.completedTxHeaders[section]
    }()
    return header
  }

  func numberRows(for section: Int) -> Int {
    let header = self.header(for: section)
    return (self.isShowingPending ? self.pendingTxData[header]?.count : self.completedTxData[header]?.count) ?? 0
  }

  func completedTransaction(for row: Int, at section: Int) -> Transaction? {
    let header = self.header(for: section)
    if let trans = self.completedTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  func pendingTransaction(for row: Int, at section: Int) -> Transaction? {
    let header = self.header(for: section)
    if let trans = self.pendingTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  var normalAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    NSAttributedStringKey.foregroundColor: UIColor.white,
  ]

  var selectedAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    NSAttributedStringKey.foregroundColor: UIColor.Kyber.enygold,
  ]
}

class KNHistoryViewController: KNBaseViewController {

  weak var delegate: KNHistoryViewControllerDelegate?
  fileprivate var viewModel: KNHistoryViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var transactionsTextLabel: UILabel!

  @IBOutlet weak var emptyStateContainerView: UIView!
  @IBOutlet weak var emptyStateDescLabel: UILabel!

  @IBOutlet weak var rateMightChangeContainerView: UIView!
  @IBOutlet weak var ratesMightChangeTextLabel: UILabel!
  @IBOutlet weak var ratesMightChangeDescTextLabel: UILabel!
  @IBOutlet weak var bottomPaddingConstraintForRateMightChange: NSLayoutConstraint!

  @IBOutlet weak var segmentedControl: UISegmentedControl!

  @IBOutlet weak var transactionCollectionView: UICollectionView!
  @IBOutlet weak var transactionCollectionViewBottomConstraint: NSLayoutConstraint!

  init(viewModel: KNHistoryViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNHistoryViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUIWhenDataDidChange()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    KNCrashlyticsUtil.logCustomEvent(withName: "history", customAttributes: ["type": "pending_tx"])
    self.setupNavigationBar()
    self.setupCollectionView()
  }

  fileprivate func setupNavigationBar() {
    let style = KNAppStyleType.current
    self.transactionsTextLabel.text = NSLocalizedString("transactions", value: "Transactions", comment: "")
    self.view.backgroundColor = style.mainBackgroundColor
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.segmentedControl.rounded(
      color: .white,
      width: 1,
      radius: style.buttonRadius(for: self.segmentedControl.frame.height)
    )
    self.segmentedControl.setTitle(NSLocalizedString("pending", value: "Pending", comment: ""), forSegmentAt: 0)
    self.segmentedControl.setTitle(NSLocalizedString("mined", value: "Mined", comment: ""), forSegmentAt: 1)
    self.segmentedControl.setTitleTextAttributes(self.viewModel.normalAttributes, for: .normal)
    self.segmentedControl.setTitleTextAttributes(self.viewModel.selectedAttributes, for: .selected)
  }

  fileprivate func setupCollectionView() {
    let nib = UINib(nibName: KNHistoryTransactionCollectionViewCell.className, bundle: nil)
    self.transactionCollectionView.register(nib, forCellWithReuseIdentifier: KNHistoryTransactionCollectionViewCell.cellID)
    let headerNib = UINib(nibName: KNTransactionCollectionReusableView.className, bundle: nil)
    self.transactionCollectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: KNTransactionCollectionReusableView.viewID)
    self.transactionCollectionView.delegate = self
    self.transactionCollectionView.dataSource = self

    self.ratesMightChangeTextLabel.text = NSLocalizedString("rates.might.change", value: "Rates might change", comment: "")
    self.ratesMightChangeDescTextLabel.text = NSLocalizedString("rates.for.token.swap.are.not.final.until.mined", value: "Rates for token swap are not final until swapping transactions are completed (mined)", comment: "")
    self.bottomPaddingConstraintForRateMightChange.constant = self.bottomPaddingSafeArea()
    self.updateUIWhenDataDidChange()
  }

  fileprivate func updateUIWhenDataDidChange() {
    self.emptyStateContainerView.isHidden = self.viewModel.isEmptyStateHidden
    self.emptyStateDescLabel.text = self.viewModel.emptyStateDescLabelString
    self.rateMightChangeContainerView.isHidden = self.viewModel.isRateMightChangeHidden
    self.transactionCollectionView.isHidden = self.viewModel.isTransactionCollectionViewHidden
    self.transactionCollectionViewBottomConstraint.constant = self.viewModel.transactionCollectionViewBottomPaddingConstraint + self.bottomPaddingSafeArea()
    self.transactionCollectionView.reloadData()
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraintsIfNeeded()
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.historyViewController(self, run: .dismiss)
  }

  @IBAction func segmentedControlValueDidChange(_ sender: UISegmentedControl) {
    self.viewModel.updateIsShowingPending(sender.selectedSegmentIndex == 0)
    self.updateUIWhenDataDidChange()
    KNCrashlyticsUtil.logCustomEvent(withName: "history", customAttributes: ["type": self.viewModel.isShowingPending ? "pending_tx" : "mined_tx"])
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.historyViewController(self, run: .dismiss)
    }
  }
}

extension KNHistoryViewController {
  func coordinatorUpdateCompletedTransactions(
    data: [String: [Transaction]],
    dates: [String],
    currentWallet: KNWalletObject
    ) {
    self.viewModel.update(completedTxData: data, completedTxHeaders: dates)
    self.viewModel.updateCurrentWallet(currentWallet)
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdatePendingTransaction(
    data: [String: [Transaction]],
    dates: [String],
    currentWallet: KNWalletObject
    ) {
    self.viewModel.update(pendingTxData: data, pendingTxHeaders: dates)
    self.viewModel.updateCurrentWallet(currentWallet)
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdateWalletObjects() {
    guard let currentWallet = KNWalletStorage.shared.get(forPrimaryKey: self.viewModel.currentWallet.address) else { return }
    self.viewModel.updateCurrentWallet(currentWallet)
    self.updateUIWhenDataDidChange()
  }
}

extension KNHistoryViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    KNCrashlyticsUtil.logCustomEvent(withName: "history", customAttributes: ["type": "selected_tx"])
    if self.segmentedControl.selectedSegmentIndex == 0 {
      guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return }
      self.delegate?.historyViewController(self, run: .selectTransaction(transaction: transaction))
    } else {
      guard let transaction = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) else { return }
      self.delegate?.historyViewController(self, run: .selectTransaction(transaction: transaction))
    }
  }
}

extension KNHistoryViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      return CGSize(
        width: collectionView.frame.width,
        height: KNHistoryTransactionCollectionViewCell.height
      )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: 44
    )
  }
}

extension KNHistoryViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.viewModel.numberSections
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows(for: section)
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNHistoryTransactionCollectionViewCell.cellID, for: indexPath) as! KNHistoryTransactionCollectionViewCell
    cell.delegate = self
    if self.viewModel.isShowingPending {
      guard let tx = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      let model = KNHistoryTransactionCollectionViewModel(
        transaction: tx,
        ownerAddress: self.viewModel.currentWallet.address,
        ownerWalletName: self.viewModel.currentWallet.name,
        index: indexPath.row
      )
      cell.updateCell(with: model)
    } else {
      guard let tx = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      let model = KNHistoryTransactionCollectionViewModel(
        transaction: tx,
        ownerAddress: self.viewModel.currentWallet.address,
        ownerWalletName: self.viewModel.currentWallet.name,
        index: indexPath.row
      )
      cell.updateCell(with: model)
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KNTransactionCollectionReusableView.viewID, for: indexPath) as! KNTransactionCollectionReusableView
      headerView.updateView(with: self.viewModel.header(for: indexPath.section))
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}

extension KNHistoryViewController: KNHistoryTransactionCollectionViewCellDelegate {
  func historyTransactionCollectionViewCell(_ cell: KNHistoryTransactionCollectionViewCell, openDetails transaction: Transaction) {
    self.delegate?.historyViewController(self, run: .selectTransaction(transaction: transaction))
  }
}
