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
  fileprivate lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy MMM dd"
    return formatter
  }()

  let user: IEOUser
  fileprivate(set) var transactions: [IEOTransaction] = [] {
    didSet { self.setupData() }
  }
  fileprivate(set) var headers: [String] = []
  fileprivate(set) var sectionData: [String: [IEOTransaction]] = [:]

  init() {
    self.user = IEOUserStorage.shared.user!
    self.transactions = IEOTransactionStorage.shared.objects
  }

  fileprivate mutating func setupData() {
    self.headers = {
      let dates = self.transactions.map { return self.dateFormatter.string(from: $0.createdDate) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    self.sectionData = {
      var data: [String: [IEOTransaction]] = [:]
      self.transactions.forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.createdDate)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: tx.createdDate)] = trans
      }
      return data
    }()
  }

  var numberSections: Int { return self.headers.count }

  func header(for section: Int) -> String { return self.headers[section] }

  func numberRows(for section: Int) -> Int {
    return self.sectionData[self.headers[section]]?.count ?? 0
  }

  func transaction(for row: Int, in section: Int) -> IEOTransaction? {
    if let trans = self.sectionData[self.headers[section]] {
      return trans[row]
    }
    return nil
  }

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
    let cellNib = UINib(nibName: IEOTransactionCollectionViewCell.className, bundle: nil)
    self.transactionListCollectionView.register(
      cellNib,
      forCellWithReuseIdentifier: IEOTransactionCollectionViewCell.cellID
    )
    let headerNib = UINib(
      nibName: KNTransactionCollectionReusableView.className,
      bundle: nil
    )
    self.transactionListCollectionView.register(
      headerNib,
      forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
      withReuseIdentifier: KNTransactionCollectionReusableView.viewID
    )
    self.transactionListCollectionView.delegate = self
    self.transactionListCollectionView.dataSource = self
    self.coordinatorUpdateTransactionList(self.viewModel.transactions)
  }

  func coordinatorUpdateTransactionList(_ transactions: [IEOTransaction]) {
    self.viewModel.update(transactions: transactions)
    self.emptyStateLabel.isHidden = self.viewModel.numberSections > 0
    self.transactionListCollectionView.isHidden = self.viewModel.numberSections == 0
    self.transactionListCollectionView.reloadData()
    self.setAllTransactionsViewed()
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
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    NSLog("----KyberGO: Set All Transactions Viewed----")
    let provider = MoyaProvider<KyberGOService>()
    provider.request(.markView(accessToken: accessToken)) { result in
      switch result {
      case .success(let resp):
        do {
          _ = try resp.filterSuccessfulStatusCodes()
          NSLog("----KyberGO: Set All Transactions Viewed Successfully----")
          IEOTransactionStorage.shared.markAllViewed()
          KNNotificationUtil.postNotification(for: kIEOTxListUpdateNotificationKey)
        } catch let error {
          NSLog("----KyberGO: Set All Transactions Viewed error: \(error.prettyError)----")
        }
      case .failure(let error):
        NSLog("----KyberGO: Set All Transactions Viewed error: \(error.prettyError)----")
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
    guard let transaction = self.viewModel.transaction(for: indexPath.row, in: indexPath.section) else { return }
    self.delegate?.ieoProfileViewController(self, run: .select(transaction: transaction))
  }
}

extension IEOProfileViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.viewModel.numberSections
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows(for: section)
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: IEOTransactionCollectionViewCell.cellID,
      for: indexPath
    ) as! IEOTransactionCollectionViewCell
    guard let transaction = self.viewModel.transaction(for: indexPath.row, in: indexPath.section) else { return cell }
    let cellModel: IEOTransactionCollectionViewModel = {
      let ieoObject = IEOObjectStorage.shared.getObject(primaryKey: transaction.ieoID)
      return IEOTransactionCollectionViewModel(
        transaction: transaction,
        ieoObject: ieoObject
      )
    }()
    cell.updateCell(with: cellModel)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: 32
    )
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: KNTransactionCollectionReusableView.viewID,
        for: indexPath
      ) as! KNTransactionCollectionReusableView
      headerView.updateView(with: self.viewModel.header(for: indexPath.section))
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}
