// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNManageOrdersViewModel {
  let kPageSize: Int = 400
  fileprivate(set) var numberPages: Int = 1
  fileprivate(set) var orders: [KNOrderObject] = []
  fileprivate(set) var displayedOrders: [KNOrderObject] = []
  var cancelOrder: KNOrderObject?

  var isDateDesc: Bool = true {
    didSet { self.updateDisplayOrders() }
  }
  var timeIntervalType: Int = 0 { // 1 day/1 week/1 month/3 months
    didSet { self.updateDisplayOrders() }
  }

  var fromTime: TimeInterval {
    if self.timeIntervalType == 0 { return Date().timeIntervalSince1970 - 24.0 * 60.0 * 60.0 }
    if self.timeIntervalType == 1 { return Date().timeIntervalSince1970 - 7.0 * 24.0 * 60.0 * 60.0 }
    let months = self.timeIntervalType == 2 ? -1 : -3
    if let date = Calendar.current.date(byAdding: .month, value: months, to: Date()) {
      return date.timeIntervalSince1970
    }
    return Date().timeIntervalSince1970 - Double(months * -1) * 30.0 * 24.0 * 60.0 * 60.0
  }

  var selectedPairs: [String]? {
    didSet { self.updateDisplayOrders() }
  }
  var selectedStates: [Int] = [0, 1, 2] { // default open, in progress, filled
    didSet { self.updateDisplayOrders() }
  }
  var selectedAddresses: [String]? {
    didSet { self.updateDisplayOrders() }
  }

  init(orders: [KNOrderObject]) {
    self.orders = orders
    self.cancelOrder = nil
    self.updateDisplayOrders()
  }

  fileprivate func updateDisplayOrders() {
    let fromTime = self.fromTime
    self.displayedOrders = self.orders.filter({
      // filter pairs
      let pair = "\($0.srcTokenSymbol) ➞ \($0.destTokenSymbol)"
      return self.selectedPairs == nil || self.selectedPairs?.contains(pair) == true
    }).filter({
      // filter states
      return self.selectedStates.contains($0.stateValue) == true
    }).filter({
      // filter addresses
      var addr = $0.sender.lowercased()
      addr = "\(addr.prefix(6))...\(addr.suffix(4))"
      return self.selectedAddresses == nil || self.selectedAddresses?.contains(addr) == true
    }).filter({
      // filter date
      return $0.dateToDisplay.timeIntervalSince1970 >= fromTime
    }).sorted(by: {
      // sort
      if self.isDateDesc { return $0.dateToDisplay > $1.dateToDisplay }
      return $0.dateToDisplay < $1.dateToDisplay
    })
  }

  func updateOrders(_ orders: [KNOrderObject]) {
    self.orders = orders
    self.updateDisplayOrders()
    if orders.count == self.numberPages * kPageSize {
      self.numberPages += 1
      // increase number pages needed to be loaded
    }
  }
}

protocol KNManageOrdersViewControllerDelegate: class {
}

class KNManageOrdersViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var filterButton: UIButton!
  @IBOutlet weak var oneDayButton: UIButton!
  @IBOutlet weak var oneWeekButton: UIButton!
  @IBOutlet weak var oneMonthButton: UIButton!
  @IBOutlet weak var threeMonthButton: UIButton!

  @IBOutlet weak var orderCollectionView: UICollectionView!
  @IBOutlet weak var emptyStateLabel: UILabel!
  @IBOutlet weak var bottomPaddingOrderCollectionViewConstraint: NSLayoutConstraint!

  @IBOutlet weak var faqButton: UIButton!
  fileprivate var loadingTimer: Timer?

  fileprivate(set) var viewModel: KNManageOrdersViewModel
  weak var delegate: KNManageOrdersViewControllerDelegate?
  fileprivate(set) var filterVC: KNFilterLimitOrderViewController?

  init(viewModel: KNManageOrdersViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNManageOrdersViewController.className, bundle: nil)
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

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.listOrdersDidUpdate(_:)),
      name: NSNotification.Name(rawValue: kUpdateListOrdersNotificationKey),
      object: nil
    )

    self.loadListOrders(isDisplayLoading: true)
    self.loadingTimer?.invalidate()
    self.loadingTimer = Timer.scheduledTimer(
      withTimeInterval: 15.0, repeats: true, block: { [weak self] _ in
        self?.loadListOrders()
      }
    )
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(rawValue: kUpdateListOrdersNotificationKey),
      object: nil
    )
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.filterButton.setTitle("Filter".toBeLocalised(), for: .normal)
    self.oneDayButton.setTitle("1 Day".toBeLocalised(), for: .normal)
    self.oneWeekButton.setTitle("1 Week".toBeLocalised(), for: .normal)
    self.oneMonthButton.setTitle("1 Month".toBeLocalised(), for: .normal)
    self.threeMonthButton.setTitle("3 Months".toBeLocalised(), for: .normal)

    self.emptyStateLabel.text = "No order found".toBeLocalised()
    let nib = UINib(nibName: KNLimitOrderCollectionViewCell.className, bundle: nil)
    self.orderCollectionView.register(nib, forCellWithReuseIdentifier: KNLimitOrderCollectionViewCell.cellID)
    self.orderCollectionView.delegate = self
    self.orderCollectionView.dataSource = self

    self.bottomPaddingOrderCollectionViewConstraint.constant = self.bottomPaddingSafeArea() + 12.0

    self.faqButton.setTitle("Wonder why your orders are not filled?".toBeLocalised(), for: .normal)
    self.faqButton.titleLabel?.numberOfLines = 2
    self.faqButton.titleLabel?.lineBreakMode = .byWordWrapping
    self.faqButton.rounded(radius: 4.0)

    self.updateDisplayTimeInterval(3)
  }

  fileprivate func updateDisplayTimeInterval(_ type: Int) {
    self.viewModel.timeIntervalType = type

    let normalColor = UIColor(red: 90, green: 94, blue: 103)
    let highLightedColor = UIColor(red: 255, green: 144, blue: 8)

    self.oneDayButton.setTitleColor(
      type == 0 ? highLightedColor : normalColor,
      for: .normal
    )
    self.oneWeekButton.setTitleColor(
      type == 1 ? highLightedColor : normalColor,
      for: .normal
    )
    self.oneMonthButton.setTitleColor(
      type == 2 ? highLightedColor : normalColor,
      for: .normal
    )
    self.threeMonthButton.setTitleColor(
      type == 3 ? highLightedColor : normalColor,
      for: .normal
    )
    self.updateCollectionView()
  }

  fileprivate func updateCollectionView() {
    self.emptyStateLabel.isHidden = !self.viewModel.displayedOrders.isEmpty
    self.orderCollectionView.isHidden = self.viewModel.displayedOrders.isEmpty
    self.faqButton.isHidden = self.viewModel.displayedOrders.isEmpty
    self.orderCollectionView.reloadData()
  }

  fileprivate func openFilterView() {
    let allPairs = self.viewModel.orders.map({ return "\($0.srcTokenSymbol) ➞ \($0.destTokenSymbol)" }).unique.sorted(by: { return $0 < $1 })
    let allAddresses = self.viewModel.orders
      .map({ (order) -> String in
        let addr = order.sender.lowercased()
        return "\(addr.prefix(6))...\(addr.suffix(4))"
      }).unique.sorted(by: { return $0 < $1 })
    let viewModel = KNFilterLimitOrderViewModel(
      isDateDesc: self.viewModel.isDateDesc,
      pairs: self.viewModel.selectedPairs,
      status: self.viewModel.selectedStates,
      addresses: self.viewModel.selectedAddresses,
      allPairs: allPairs,
      allAddresses: allAddresses
    )
    self.filterVC = KNFilterLimitOrderViewController(viewModel: viewModel)
    self.filterVC?.delegate = self
    self.filterVC?.loadViewIfNeeded()

    self.navigationController?.pushViewController(self.filterVC!, animated: true)
  }

  @objc func listOrdersDidUpdate(_ sender: Any) {
    let orders = KNLimitOrderStorage.shared.orders.map({ return $0.clone() })
    self.updateListOrders(orders)
  }

  func updateListOrders(_ orders: [KNOrderObject]) {
    self.viewModel.updateOrders(orders)
    self.updateCollectionView()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func oneDayButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["button": "one_day"])
    self.updateDisplayTimeInterval(0)
  }

  @IBAction func oneWeekButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["button": "one_week"])
    self.updateDisplayTimeInterval(1)
  }

  @IBAction func oneMonthButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["button": "one_month"])
    self.updateDisplayTimeInterval(2)
  }

  @IBAction func threeMonthButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["button": "three_months"])
    self.updateDisplayTimeInterval(3)
  }

  @IBAction func filterButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["button": "filter"])
    self.openFilterView()
  }

  @IBAction func openFAQButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["button": "faq"])
    let url = "\(KNEnvironment.default.profileURL)/faq#I-submitted-the-limit-order-but-it-was-not-triggered-even-though-my-desired-price-was-hit"
    self.navigationController?.openSafari(with: url)
  }

  fileprivate func loadListOrders(isDisplayLoading: Bool = false) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
      self.navigationController?.popViewController(animated: true)
      return
    }
    if isDisplayLoading { self.displayLoading() }

    var orders: [KNOrderObject] = []
    var errorMessage: String?

    let group = DispatchGroup()
    for id in 0..<self.viewModel.numberPages {
      group.enter()
      KNLimitOrderServerCoordinator.shared.getListOrders(accessToken: accessToken, pageIndex: id + 1, pageSize: self.viewModel.kPageSize) { [weak self] result in
        guard let _ = self else {
          group.leave()
          return
        }
        switch result {
        case .success(let ords):
          ords.forEach({ or in
            if orders.first(where: { o -> Bool in return o.id == or.id }) == nil {
              orders.append(or)
            }
          })
        case .failure:
          KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["load_list_orders": "failed"])
          errorMessage = "Can not load your orders right now".toBeLocalised()
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      if isDisplayLoading { self.hideLoading() }
      if errorMessage == nil {
        KNLimitOrderStorage.shared.updateOrdersFromServer(orders)
        self.updateListOrders(orders)
      } else if let error = errorMessage, isDisplayLoading {
        let alert = UIAlertController(
          title: NSLocalizedString("error", value: "Error", comment: ""),
          message: error,
          preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("try.again", value: "Try Again", comment: ""), style: .default, handler: { _ in
          self.loadListOrders(isDisplayLoading: true)
        }))
      }
    }
  }
}

// MARK: Related orders
extension KNManageOrdersViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 12.0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets.zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNLimitOrderCollectionViewCell.height
    )
  }
}

extension KNManageOrdersViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    let order = self.viewModel.displayedOrders[indexPath.row]
    if let cancelOrder = self.viewModel.cancelOrder, cancelOrder.id == order.id {
      self.viewModel.cancelOrder = nil
      collectionView.reloadItems(at: [indexPath])
    } else if order.state == .filled,
      let hash = order.txHash,
      let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint,
      let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.openSafari(with: url)
    }
  }
}

extension KNManageOrdersViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.displayedOrders.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KNLimitOrderCollectionViewCell.cellID,
      for: indexPath
      ) as! KNLimitOrderCollectionViewCell
    let order = self.viewModel.displayedOrders[indexPath.row]
    let isReset: Bool = {
      if let cancelBtnOrder = self.viewModel.cancelOrder {
        return cancelBtnOrder.id != order.id
      }
      return true
    }()
    cell.updateCell(with: order, isReset: isReset)
    cell.delegate = self
    return cell
  }
}

extension KNManageOrdersViewController: KNLimitOrderCollectionViewCellDelegate {
  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, cancelPressed order: KNOrderObject) {
    guard let id = self.viewModel.displayedOrders.firstIndex(where: { $0.id == order.id }) else {
      return
    }
    let cancelOrderVC = KNCancelOrderConfirmPopUp(order: order)
    cancelOrderVC.loadViewIfNeeded()
    cancelOrderVC.modalTransitionStyle = .crossDissolve
    cancelOrderVC.modalPresentationStyle = .overFullScreen
    cancelOrderVC.delegate = self
    self.present(cancelOrderVC, animated: true) {
      self.viewModel.cancelOrder = nil
      let indexPath = IndexPath(row: id, section: 0)
      self.orderCollectionView.reloadItems(at: [indexPath])
    }
  }

  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, showWarning order: KNOrderObject) {
    self.showTopBannerView(
      with: "",
      message: order.messages,
      icon: UIImage(named: "warning_icon"),
      time: 1.5
    )
  }
}

extension KNManageOrdersViewController: KNFilterLimitOrderViewControllerDelegate {
  func filterLimitOrderViewController(_ controller: KNFilterLimitOrderViewController, isDateDesc: Bool, pairs: [String]?, status: [Int], addresses: [String]?) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["filter": "applied_pairs_\(pairs?.joined(separator: ",") ?? "all")"])
    self.viewModel.isDateDesc = isDateDesc
    self.viewModel.selectedPairs = pairs
    self.viewModel.selectedStates = status
    self.viewModel.selectedAddresses = addresses
    self.updateCollectionView()
  }
}

extension KNManageOrdersViewController: KNCancelOrderConfirmPopUpDelegate {
  func cancelOrderConfirmPopup(_ controller: KNCancelOrderConfirmPopUp, didConfirmCancel order: KNOrderObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_order", customAttributes: ["cancel": "confirmed"])
    self.loadListOrders(isDisplayLoading: true)
  }
}
