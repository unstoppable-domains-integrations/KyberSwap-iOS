// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNHistoryCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession
  var coordinator: [Coordinator] = []

  weak var delegate: KNSessionDelegate?

  lazy var rootViewController = KNHistoryViewController = {
    let controller = KNHistoryViewController(delegate: self)
    controller.loadViewIfNeeded()
    return controller
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.applyStyle()
    self.session = session
  }

  func start() {
    self.navigationController = [self.rootViewController]
  }

  func stop() {
  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewControllerDidSelectTransaction(_ transaction: Transaction) {
  }

  func historyViewControllerDidClickExit() {
    self.delegate?.userDidClickExitSession()
  }
}
