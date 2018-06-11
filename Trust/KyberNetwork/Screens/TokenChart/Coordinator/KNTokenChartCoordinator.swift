// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNTokenChartCoordinatorDelegate: class {
  func tokenChartCoordinator(sell token: TokenObject)
  func tokenChartCoordinator(buy token: TokenObject)
}

class KNTokenChartCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession
  let token: TokenObject
  var coordinators: [Coordinator] = []
  var balances: [String: Balance] = [:]

  weak var delegate: KNTokenChartCoordinatorDelegate?

  lazy var rootViewController: KNTokenChartViewController = {
    let viewModel = KNTokenChartViewModel(token: self.token)
    let controller = KNTokenChartViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?

  init(
    navigationController: UINavigationController,
    session: KNSession,
    balances: [String: Balance],
    token: TokenObject
    ) {
    self.navigationController = navigationController
    self.session = session
    self.balances = balances
    self.token = token
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }

  func coordinatorTokenBalancesDidUpdate(balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }

  func coordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }
}

extension KNTokenChartCoordinator: KNTokenChartViewControllerDelegate {
  func tokenChartViewController(didPressBack sender: KNTokenChartViewController) {
    self.stop()
  }

  func tokenChartViewController(_ sender: KNTokenChartViewController, shouldBuy token: TokenObject) {
    self.delegate?.tokenChartCoordinator(buy: token)
  }

  func tokenChartViewController(_ sender: KNTokenChartViewController, shouldSell token: TokenObject) {
    self.delegate?.tokenChartCoordinator(sell: token)
  }

  func tokenChartViewController(_ sender: KNTokenChartViewController, shouldSend token: TokenObject) {
    self.sendTokenCoordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      from: token
    )
//    self.sendTokenCoordinator?.delegate = self
    self.sendTokenCoordinator?.start()
  }
}
