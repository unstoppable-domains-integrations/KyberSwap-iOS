// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KMarketViewCoordinatorDelegate: class {
  func kMarketViewCoordinator(_ coordinator: KMarketViewCoordinator, run event: KMarketsViewEvent)
}

class KMarketViewCoordinator: Coordinator {

  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  let currencyType: KWalletCurrencyType

  weak var delegate: KMarketViewCoordinatorDelegate?

  lazy var rootViewController: KMarketViewController = {
    let viewModel = KMarketsViewModel(currencyType: self.currencyType)
    let controller = KMarketViewController(viewModel: viewModel)
    controller.delegate = self
    controller.loadViewIfNeeded()
    return controller
  }()

  init(
    navigationController: UINavigationController,
    currencyType: KWalletCurrencyType
    ) {
    self.navigationController = navigationController
    self.currencyType = currencyType
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop(completion: @escaping () -> Void) {
    self.navigationController.popViewController(animated: true, completion: completion)
  }

  func coordinatorDidUpdateNewSession() {
    let viewModel = KMarketsViewModel(currencyType: self.currencyType)
    self.rootViewController.coordinatorUpdateSessionWithNewViewModel(viewModel)
  }

  func coordinatorDidUpdateTokenObjects(_ tokenObjects: [TokenObject]) {
    self.rootViewController.coordinatorUpdateTokenObjects(tokenObjects)
  }

  func coordinatorUpdateTrackerRate() {
    self.rootViewController.coordinatorUpdateTrackerRate()
  }
}

extension KMarketViewCoordinator: KMarketViewControllerDelegate {
  func kMarketViewController(_ controller: KMarketViewController, run event: KMarketsViewEvent) {
    self.delegate?.kMarketViewCoordinator(self, run: event)
  }
}
