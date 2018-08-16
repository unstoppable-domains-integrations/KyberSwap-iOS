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
  @IBOutlet weak var pendingTxNotiView: UIView!

  @IBOutlet var bottomSeparators: [UIView]!

  @IBOutlet weak var ieoTableView: UITableView!
  @IBOutlet weak var noTokenSalesFoundLabel: UILabel!

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
    self.userAccountImageView.rounded(
      color: .white,
      width: 2,
      radius: self.userAccountImageView.frame.width / 2.0
    )
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.accountImageViewDidTap(_:)))
    self.userAccountImageView.addGestureRecognizer(tapGesture)
    self.userAccountImageView.isUserInteractionEnabled = true
    self.pendingTxNotiView.rounded(radius: self.pendingTxNotiView.frame.width / 2.0)
    self.pendingTxNotiView.isHidden = true
    self.coordinatorUpdateListKyberGOTx(IEOTransactionStorage.shared.objects)
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

  fileprivate func updateUIs() {
    self.ieoTableView.isHidden = self.viewModel.isTokenSalesListHidden
    self.noTokenSalesFoundLabel.isHidden = self.viewModel.isEmptyStateHidden
    self.bottomSeparators.forEach({ $0.backgroundColor = $0.tag == self.viewModel.displayType.rawValue ? UIColor.Kyber.shamrock : UIColor.clear })
    self.ieoTableView.reloadData()
  }

  func coordinatorDidUpdateListKGO(_ objects: [IEOObject]) {
    self.viewModel.updateObjects(objects)
    self.updateUIs()
  }

  func coordinatorUserDidSignInSuccessfully() {
    // TODO: Update status
  }

  func coordinatorDidUpdateIsHalted(_ halted: Bool, object: IEOObject) {
    self.viewModel.updateIsHalted(halted, object: object)
    self.ieoTableView.reloadData()
  }

  func coordinatorDidSignOut() {
    self.pendingTxNotiView.isHidden = true
    self.showSuccessTopBannerMessage(
      with: "Logged out successfully".toBeLocalised(),
      message: "Login again if you want to see your transactions and buy token sales".toBeLocalised()
    )
  }

  func coordinatorUpdateListKyberGOTx(_ transactions: [IEOTransaction]) {
    let unviewedTrans = transactions.filter({ !$0.viewed })
    self.pendingTxNotiView.isHidden = unviewedTrans.isEmpty
  }

  @objc func accountImageViewDidTap(_ sender: UITapGestureRecognizer) {
    self.delegate?.kyberGOHomePageViewController(self, run: .selectAccount)
  }

  @IBAction func tokenSaleListTypePressed(_ sender: UIButton) {
    let type = IEOObjectType(rawValue: sender.tag) ?? .active
    self.viewModel.updateDisplayType(type)
    UIView.animate(withDuration: 0.32) {
      self.updateUIs()
      if !self.viewModel.isTokenSalesListHidden {
        self.ieoTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
      }
      self.view.layoutIfNeeded()
    }
  }
}

extension KGOHomePageViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    guard let object = self.viewModel.displayObject(at: indexPath.row) else { return }
    let listObjects: [IEOObject] = self.viewModel.displayObjects
    self.delegate?.kyberGOHomePageViewController(self, run: .select(object: object, listObjects: listObjects))
  }
}

extension KGOHomePageViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kIEOTableViewCellID, for: indexPath) as! KGOIEOTableViewCell
    guard let object = self.viewModel.displayObject(at: indexPath.row) else { return cell }
    let model = KGOIEOTableViewCellModel(
      object: object,
      isHalted: self.viewModel.isHalted(for: object),
      index: indexPath.row
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
