// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNHistoryViewControllerDelegate: class {
  func historyViewControllerDidSelectTransaction(_ transaction: Transaction)
  func historyViewControllerDidClickExit()
}

class KNHistoryViewController: KNBaseViewController {

  fileprivate weak var delegate: KNHistoryViewControllerDelegate?

  fileprivate var transactions: [KNHistoryTransaction] = []
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
    self.transactionCollectionView.delegate = self
    self.transactionCollectionView.dataSource = self
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.historyViewControllerDidClickExit()
  }
}

extension KNHistoryViewController {
  func coordinatorUpdateHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    self.transactions = transactions
  }
}

extension KNHistoryViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
}

extension KNHistoryViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.transactions.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNTransactionCollectionViewCell.cellID, for: indexPath) as! KNTransactionCollectionViewCell
    let tran = self.transactions[indexPath.row]
    cell.updateCell(with: tran)
    return cell
  }
}
