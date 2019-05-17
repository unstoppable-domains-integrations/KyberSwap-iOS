// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNManageOrdersViewModel {
  fileprivate(set) var orders: [KNOrderObject] = []
  fileprivate(set) var displayedOrders: [KNOrderObject] = []
  fileprivate var cancelOrder: KNOrderObject?

  init(orders: [KNOrderObject]) {
    self.orders = orders
    self.displayedOrders = orders
    self.cancelOrder = nil
  }
}

protocol KNManageOrdersViewControllerDelegate: class {
}

class KNManageOrdersViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var filterTextLabel: UILabel!
  @IBOutlet weak var oneDayButton: UIButton!
  @IBOutlet weak var oneWeekButton: UIButton!
  @IBOutlet weak var oneMonthButton: UIButton!
  @IBOutlet weak var threeMonthButton: UIButton!

  @IBOutlet weak var separatorView: UIView!

  @IBOutlet weak var pairButton: UIButton!
  @IBOutlet weak var dateButton: UIButton!
  @IBOutlet weak var statusButton: UIButton!

  @IBOutlet weak var orderCollectionView: UICollectionView!
  @IBOutlet weak var emptyStateLabel: UILabel!
  @IBOutlet weak var bottomPaddingOrderCollectionViewConstraint: NSLayoutConstraint!

  fileprivate(set) var viewModel: KNManageOrdersViewModel
  weak var delegate: KNManageOrdersViewControllerDelegate?

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

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorView.removeSublayer(at: 0)
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.border)
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.border)
    self.filterTextLabel.text = "Filter".toBeLocalised().uppercased()
    self.oneDayButton.setTitle("1 Day".toBeLocalised(), for: .normal)
    self.oneWeekButton.setTitle("1 Week".toBeLocalised(), for: .normal)
    self.oneMonthButton.setTitle("1 Month".toBeLocalised(), for: .normal)
    self.threeMonthButton.setTitle("3 Months".toBeLocalised(), for: .normal)

    self.pairButton.setTitle("Pair".toBeLocalised(), for: .normal)
    self.pairButton.semanticContentAttribute = .forceRightToLeft
    self.dateButton.setTitle("Date".toBeLocalised(), for: .normal)
    self.dateButton.semanticContentAttribute = .forceRightToLeft
    self.statusButton.setTitle("Status".toBeLocalised(), for: .normal)
    self.statusButton.semanticContentAttribute = .forceRightToLeft

    self.emptyStateLabel.text = "No order found".toBeLocalised()
    let nib = UINib(nibName: KNLimitOrderCollectionViewCell.className, bundle: nil)
    self.orderCollectionView.register(nib, forCellWithReuseIdentifier: KNLimitOrderCollectionViewCell.cellID)
    self.orderCollectionView.delegate = self
    self.orderCollectionView.dataSource = self

    self.bottomPaddingOrderCollectionViewConstraint.constant = self.bottomPaddingSafeArea()

    self.updateCollectionView()
  }

  fileprivate func updateCollectionView() {
    self.emptyStateLabel.isHidden = !self.viewModel.displayedOrders.isEmpty
    self.orderCollectionView.isHidden = self.viewModel.displayedOrders.isEmpty
    self.orderCollectionView.reloadData()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func oneDayButtonPressed(_ sender: Any) {
  }

  @IBAction func oneWeekButtonPressed(_ sender: Any) {
  }

  @IBAction func oneMonthButtonPressed(_ sender: Any) {
  }

  @IBAction func threeMonthButtonPressed(_ sender: Any) {
  }

  @IBAction func pairButtonPressed(_ sender: Any) {
  }

  @IBAction func dateButtonPressed(_ sender: Any) {
  }

  @IBAction func statusButtonPressed(_ sender: Any) {
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
    let alertController = UIAlertController(
      title: "".toBeLocalised(),
      message: "Do you want to cancel this order?".toBeLocalised(),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "Yes".toBeLocalised(), style: .default, handler: { _ in
      self.viewModel.cancelOrder = nil
      let indexPath = IndexPath(row: id, section: 0)
      self.orderCollectionView.reloadItems(at: [indexPath])
      self.showErrorTopBannerMessage(with: "", message: "Your order has been cancalled", time: 1.5)
    }))
    alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
      self.viewModel.cancelOrder = nil
      let indexPath = IndexPath(row: id, section: 0)
      self.orderCollectionView.reloadItems(at: [indexPath])
    }))
    self.present(alertController, animated: true, completion: nil)
  }
}
