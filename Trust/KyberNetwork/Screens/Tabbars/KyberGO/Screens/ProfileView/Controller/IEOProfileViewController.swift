// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya

enum IEOProfileViewEvent {
  case back
  case viewDidAppear
  case select(transaction: IEOTransaction)
  case signedOut
}

protocol IEOProfileViewControllerDelegate: class {
  func ieoProfileViewController(_ controller: IEOProfileViewController, run event: IEOProfileViewEvent)
}

struct IEOProfileViewModel {
  let user: IEOUser
  var transactions: [IEOTransaction] = []

  init() {
    self.user = IEOUserStorage.shared.user!
    self.transactions = IEOTransactionStorage.shared.objects
  }

  var numberRows: Int { return self.transactions.count }
  func transaction(for row: Int) -> IEOTransaction { return self.transactions[row] }

  mutating func update(transactions: [IEOTransaction]) {
    self.transactions = transactions
  }
}

class IEOProfileViewController: KNBaseViewController {

  @IBOutlet weak var navigationTitleLabel: UILabel!
  @IBOutlet weak var userImageView: UIImageView!
  @IBOutlet weak var userNameLabel: UILabel!

  @IBOutlet weak var transactionListCollectionView: UICollectionView!
  @IBOutlet weak var emptyStateLabel: UILabel!

  weak var delegate: IEOProfileViewControllerDelegate?
  fileprivate var viewModel: IEOProfileViewModel

  init(viewModel: IEOProfileViewModel) {
    self.viewModel = viewModel
    super.init(nibName: IEOProfileViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    self.setupUI()
    self.setAllTransactionsViewed()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.delegate?.ieoProfileViewController(self, run: .viewDidAppear)
  }

  fileprivate func setupUI() {
    self.userImageView.rounded(
      color: .lightGray,
      width: 0.5,
      radius: self.userImageView.frame.width / 2.0
    )
    self.userNameLabel.text = "\(self.viewModel.user.name)"

    self.emptyStateLabel.text = "Nothing in here yet.".toBeLocalised()
    let nib = UINib(nibName: IEOTransactionCollectionViewCell.className, bundle: nil)
    self.transactionListCollectionView.register(
      nib,
      forCellWithReuseIdentifier: IEOTransactionCollectionViewCell.cellID
    )
    self.transactionListCollectionView.delegate = self
    self.transactionListCollectionView.dataSource = self
    self.coordinatorUpdateTransactionList(self.viewModel.transactions)
  }

  func coordinatorUpdateTransactionList(_ transactions: [IEOTransaction]) {
    self.viewModel.update(transactions: transactions)
    self.emptyStateLabel.isHidden = self.viewModel.numberRows > 0
    self.transactionListCollectionView.isHidden = self.viewModel.numberRows == 0
    self.transactionListCollectionView.reloadData()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.ieoProfileViewController(self, run: .back)
  }

  @IBAction func signOutButtonPressed(_ sender: Any) {
    self.delegate?.ieoProfileViewController(self, run: .signedOut)
  }

  @IBAction func screenEdgePanGesture(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.ieoProfileViewController(self, run: .back)
    }
  }

  fileprivate func setAllTransactionsViewed() {
    let provider = MoyaProvider<KyberGOService>()
    provider.request(.markView) { [weak self] result in
      switch result {
      case .success:
        IEOTransactionStorage.shared.markAllViewed()
        KNNotificationUtil.postNotification(for: kIEOTxListUpdateNotificationKey)
      case .failure(let error):
        self?.displayError(error: error)
      }
    }
  }
}

extension IEOProfileViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return .zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: IEOTransactionCollectionViewCell.height
    )
  }
}

extension IEOProfileViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let transaction = self.viewModel.transaction(for: indexPath.row)
    self.delegate?.ieoProfileViewController(self, run: .select(transaction: transaction))
  }
}

extension IEOProfileViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: IEOTransactionCollectionViewCell.cellID,
      for: indexPath
    ) as! IEOTransactionCollectionViewCell
    let cellModel: IEOTransactionCollectionViewModel = {
      let transaction = self.viewModel.transaction(for: indexPath.row)
      let ieoObject = IEOObjectStorage.shared.getObject(primaryKey: transaction.ieoID)
      return IEOTransactionCollectionViewModel(
        transaction: transaction,
        ieoObject: ieoObject
      )
    }()
    cell.updateCell(with: cellModel)
    return cell
  }
}
