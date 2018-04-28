// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNNewCustomTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  let storage: KNTokenStorage
  let token: ERC20Token?
  var coordinators: [Coordinator] = []

  lazy var navController: UINavigationController = {
    let controller: KNNewCustomTokenViewController = {
      let viewModel = KNNewCustomTokenViewModel(token: self.token)
      return KNNewCustomTokenViewController(viewModel: viewModel, delegate: self)
    }()
    let navController = UINavigationController(rootViewController: controller)
    navController.applyStyle()
    return navController
  }()

  init(
    navigationController: UINavigationController,
    storage: KNTokenStorage,
    token: ERC20Token?
    ) {
    self.navigationController = navigationController
    self.storage = storage
    self.token = token
  }

  func start() {
    self.navigationController.present(navController, animated: true, completion: nil)
  }

  func stop() {
    self.navigationController.dismiss(animated: true, completion: nil)
  }
}

extension KNNewCustomTokenCoordinator: KNNewCustomTokenViewControllerDelegate {
  func didCancel(in viewController: KNNewCustomTokenViewController) {
    self.stop()
  }

  func didAddToken(_ token: ERC20Token, in viewController: KNNewCustomTokenViewController) {
    self.storage.addCustom(token: token)
    KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
    self.stop()
  }
}
