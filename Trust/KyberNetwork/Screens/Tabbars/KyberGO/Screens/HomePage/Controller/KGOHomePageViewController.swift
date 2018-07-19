// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import WebKit

enum KGOHomePageViewEvent {
  case select(object: IEOObject, listObjects: [IEOObject])
  case selectAccount
  case selectBuy(object: IEOObject)
}

protocol KGOHomePageViewControllerDelegate: class {
  func kyberGOHomePageViewController(_ controller: KGOHomePageViewController, run event: KGOHomePageViewEvent)
}

class KGOHomePageViewController: KNBaseViewController {

  fileprivate var kIEOTableViewCellID: String = "kIEOTableViewCellID"
  fileprivate var kIEOTableViewHeaderID: String = "kIEOTableViewHeaderID"

  fileprivate var isViewSetup: Bool = false
  @IBOutlet weak var topContainerView: UIView!
  @IBOutlet weak var kyberGOLabel: UILabel!
  @IBOutlet weak var userAccountImageView: UIImageView!
  @IBOutlet weak var userStatusLabel: UILabel!
  @IBOutlet weak var pendingTxNotiView: UIView!

  @IBOutlet weak var ieoTableView: UITableView!

  fileprivate var viewModel: KGOHomePageViewModel
  weak var delegate: KGOHomePageViewControllerDelegate?

  init(viewModel: KGOHomePageViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KGOHomePageViewController.className, bundle: nil)
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

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
  }

  fileprivate func setupUI() {
    self.setupTopView()
    self.setupIEOTableView()
  }

  fileprivate func setupTopView() {
    self.kyberGOLabel.text = "KyberGO"
    self.userAccountImageView.rounded(radius: self.userAccountImageView.frame.width / 2.0)
    self.userAccountImageView.backgroundColor = UIColor(hex: "f5f5f5")
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.accountImageViewDidTap(_:)))
    self.userAccountImageView.addGestureRecognizer(tapGesture)
    self.userAccountImageView.isUserInteractionEnabled = true
    self.userStatusLabel.text = IEOUserStorage.shared.user?.name ?? "Unknown"
    self.pendingTxNotiView.rounded(radius: self.pendingTxNotiView.frame.width / 2.0)
    self.pendingTxNotiView.isHidden = true
    self.coordinatorUpdateListKyberGOTx(transactions: IEOTransactionStorage.shared.objects)
  }

  func setupIEOTableView() {
    let nib = UINib(nibName: KGOIEOTableViewCell.className, bundle: nil)
    self.ieoTableView.register(nib, forCellReuseIdentifier: kIEOTableViewCellID)
    self.ieoTableView.delegate = self
    self.ieoTableView.dataSource = self
    self.ieoTableView.rowHeight = 115
    self.ieoTableView.sectionHeaderHeight = 44
    self.ieoTableView.reloadData()
  }

  func coordinatorDidUpdateListKGO(_ objects: [IEOObject]) {
    self.viewModel.updateObjects(objects)
    self.ieoTableView.reloadData()
  }

  func coordinatorUserDidSignInSuccessfully() {
    self.userStatusLabel.text = IEOUserStorage.shared.user?.name ?? "Unknown"
  }

  func coordinatorDidUpdateIsHalted(_ halted: Bool, object: IEOObject) {
    self.viewModel.updateIsHalted(halted, object: object)
    self.ieoTableView.reloadData()
  }

  func coordinatorDidSignOut() {
    self.userStatusLabel.text = "Unknown"
    self.pendingTxNotiView.isHidden = true
    self.showSuccessTopBannerMessage(
      with: "Logged out from app successfully",
      message: "You will need to open Safari and logout from your session"
    )
  }

  func coordinatorUpdateListKyberGOTx(transactions: [IEOTransaction]) {
    let unviewedTrans = transactions.filter({ !$0.viewed })
    self.pendingTxNotiView.isHidden = unviewedTrans.isEmpty
  }

  @objc func accountImageViewDidTap(_ sender: UITapGestureRecognizer) {
    self.delegate?.kyberGOHomePageViewController(self, run: .selectAccount)
  }
}

extension KGOHomePageViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let object = self.viewModel.object(for: indexPath.row, in: indexPath.section)
    let listObjects: [IEOObject] = {
      switch object.type {
      case .active: return self.viewModel.activeObjects
      case .upcoming: return self.viewModel.upcomingObjects
      case .past: return self.viewModel.pastObjects
      }
    }()
    self.delegate?.kyberGOHomePageViewController(self, run: .select(object: object, listObjects: listObjects))
  }
}

extension KGOHomePageViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.numberSections
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberRows(for: section)
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44))
    view.backgroundColor = UIColor(hex: "f5f5f5")
    let label = UILabel(frame: CGRect(x: 20.0, y: 0, width: tableView.frame.width - 40.0, height: 44))
    label.text = self.viewModel.headerTitle(for: section)
    label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
    view.addSubview(label)
    return view
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kIEOTableViewCellID, for: indexPath) as! KGOIEOTableViewCell
    let object = self.viewModel.object(for: indexPath.row, in: indexPath.section)
    let model = KGOIEOTableViewCellModel(
      object: object,
      isHalted: self.viewModel.isHalted(for: object)
    )
    cell.updateView(with: model)
    cell.delegate = self
    return cell
  }
}

extension KGOHomePageViewController: KGOIEOTableViewCellDelegate {
  func ieoTableViewCellBuyButtonPressed(for object: IEOObject, sender: KGOIEOTableViewCell) {
    self.delegate?.kyberGOHomePageViewController(self, run: .selectBuy(object: object))
  }

  func ieoTableViewCellShouldUpdateType(for object: IEOObject, sender: KGOIEOTableViewCell) {
    self.viewModel.updateObjects(self.viewModel.ieoObjects)
    self.ieoTableView.reloadData()
  }
}
