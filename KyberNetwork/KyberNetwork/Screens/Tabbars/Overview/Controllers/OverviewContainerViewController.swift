//
//  OverviewContainerViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit

enum CurrencyType {
  case eth
  case usd
}

enum OverviewContainerViewEvent {
  case send
  case receive
  case addCustomToken
}

class OverviewContainerViewModel {
  var pagerSelectedIndex = 1
  fileprivate var session: KNSession!
  let marketViewModel: OverviewMarketViewModel
  let assetsViewModel: OverviewAssetsViewModel
  let depositViewModel: OverviewDepositViewModel
  var currencyType: CurrencyType = .usd
  
  init(session: KNSession, marketViewModel: OverviewMarketViewModel, assetsViewModel: OverviewAssetsViewModel, depositViewModel: OverviewDepositViewModel) {
    self.marketViewModel = marketViewModel
    self.assetsViewModel = assetsViewModel
    self.depositViewModel = depositViewModel
    self.session = session
  }

  var displayTotalValue: String {
    let totalValueBigInt = self.assetsViewModel.totalValueBigInt + self.depositViewModel.totalValueBigInt
    let totalString = totalValueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
    return self.currencyType == .usd ? "$" + totalString : totalString
  }
}

protocol OverviewViewController: class {
  func viewControllerDidChangeCurrencyType(_ controller: OverviewViewController, type: CurrencyType)
  func coordinatorDidUpdateDidUpdateTokenList()
}

protocol OverviewContainerViewControllerDelegate: class {
  func overviewContainerViewController(_ controller: OverviewContainerViewController, run event: OverviewContainerViewEvent)
}

enum OverviewTokenListViewEvent {
  case select(token: Token)
  case buy(token: Token)
  case sell(token: Token)
  case transfer(token: Token)
}

protocol OverviewTokenListViewDelegate: class {
  func overviewTokenListView(_ controller: OverviewViewController, run event: OverviewTokenListViewEvent)
}

class OverviewContainerViewController: KNBaseViewController, OverviewViewController {
  
  let viewModel: OverviewContainerViewModel
  private let marketViewController: OverviewMarketViewController
  private let assetsViewController: OverviewAssetsViewController
  private let depositViewController: OverviewDepositViewController
  private var pageController: UIPageViewController!
  fileprivate var isViewSetup: Bool = false
  private let viewControllers: [OverviewViewController]
  @IBOutlet weak var pagerContainerView: UIView!
  @IBOutlet weak var pageSelectButtonsContainerView: UIView!
  @IBOutlet var pageSelectButtons: [UIButton]!
  @IBOutlet weak var totalValueLabel: UILabel!
  weak var delegate: OverviewContainerViewControllerDelegate?
  weak var navigationDelegate: NavigationBarDelegate?
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var receiveButton: UIButton!
  @IBOutlet weak var addTokenButton: UIButton!

  
  init(viewModel: OverviewContainerViewModel, marketViewController: OverviewMarketViewController, assetsViewController: OverviewAssetsViewController, depositViewController: OverviewDepositViewController) {
    self.viewModel = viewModel
    self.marketViewController = marketViewController
    self.assetsViewController = assetsViewController
    self.depositViewController = depositViewController
    self.viewControllers = [self.marketViewController, self.assetsViewController, self.depositViewController]
    super.init(nibName: OverviewContainerViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.updateUITotalValue()
    self.updateUIWalletList()
    self.setupUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupPageController()
    }
  }
  
  fileprivate func setupUI() {
    self.transferButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.transferButton.frame.height / 2)
    self.receiveButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.receiveButton.frame.height / 2)
    self.addTokenButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.addTokenButton.frame.height / 2)
  }
  
  fileprivate func updateUITotalValue() {
    self.totalValueLabel.text = self.viewModel.displayTotalValue
  }
  
  fileprivate func updateUIWalletList() {
    self.walletListButton.setTitle(self.viewModel.session.wallet.address.description, for: .normal)
  }

  private func setupPageController() {
    self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    self.pageController.view.backgroundColor = .clear
    self.pageController.view.frame = CGRect(
      x: 0,
      y: 0,
      width: self.pagerContainerView.frame.width,
      height: self.pagerContainerView.frame.height
    )
    self.addChildViewController(self.pageController)
    self.pagerContainerView.addSubview(self.pageController.view)
    let initialVC = self.marketViewController
    self.pageController.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
    self.pageController.didMove(toParentViewController: self)
  }
  
  @IBAction func overviewTypeButtonTapped(_ sender: UIButton) {
    let newIdx = sender.tag
    if newIdx == self.viewModel.pagerSelectedIndex { return }
    let direction: UIPageViewController.NavigationDirection = newIdx > self.viewModel.pagerSelectedIndex ? .forward : .reverse
    let controller = self.getViewControllerWithIndex(newIdx)
    self.pageController.setViewControllers([controller], direction: direction, animated: true, completion: nil)
    self.updateUIForPageSelectButton(index: newIdx)
    self.viewModel.pagerSelectedIndex = newIdx
  }
  
  @IBAction func sendButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewContainerViewController(self, run: .send)
  }
  
  @IBAction func receiveButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewContainerViewController(self, run: .receive)
  }
  
  @IBAction func addToken(_ sender: UIButton) {
    self.delegate?.overviewContainerViewController(self, run: .addCustomToken)
  }
  
  @IBAction func historyButtonTapped(_ sender: Any) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }
  
  @IBAction func walletListButtonTapped(_ sender: Any) {
    self.navigationDelegate?.viewControllerDidSelectWallets(self)
  }
  
  fileprivate func getViewControllerWithIndex(_ index: Int) -> UIViewController {
    switch index {
    case 1:
      return self.marketViewController
    case 2:
      return self.assetsViewController
    case 3:
      return self.depositViewController
    default:
      return self.marketViewController
    }
  }
  
  fileprivate func updateUIForPageSelectButton(index: Int) {
    self.pageSelectButtons.forEach { (button) in
      button.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
    }
    if let button = self.pageSelectButtonsContainerView.viewWithTag(index) as? UIButton {
      button.setTitleColor(UIColor.Kyber.SWYellow, for: .normal)
    }
  }
  
  func viewControllerDidChangeCurrencyType(_ controller: OverviewViewController, type: CurrencyType) {
    self.viewControllers.forEach { (controller) in
      controller.viewControllerDidChangeCurrencyType(self, type: type)
    }
    self.viewModel.currencyType = type
    self.updateUITotalValue()
  }
  
  func coordinatorDidUpdateDidUpdateTokenList() {
    guard self.isViewLoaded else { return }
    self.viewControllers.forEach { (viewController) in
      viewController.coordinatorDidUpdateDidUpdateTokenList()
    }
    self.updateUITotalValue()
  }
  
  func coordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.viewModel.session = session
    guard self.isViewLoaded else { return }
    self.updateUIWalletList()
  }
}
