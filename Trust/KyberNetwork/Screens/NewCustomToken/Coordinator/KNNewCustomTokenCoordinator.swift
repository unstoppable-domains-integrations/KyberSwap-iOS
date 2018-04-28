// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNNewCustomTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  let storage: KNTokenStorage
  let token: ERC20Token?
  var coordinators: [Coordinator] = []

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
    let navController: UINavigationController = {
      let controller = NewTokenViewController(token: self.token)
      controller.delegate = self
      // Don't want to modify their NewTokenViewController
      controller.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.didClickCancelButton(_:)))
      return UINavigationController(rootViewController: controller)
    }()
    self.navigationController.topViewController?.present(navController, animated: true, completion: nil)
  }

  func stop() {
    self.navigationController.topViewController?.dismiss(animated: true, completion: nil)
  }

  @objc func didClickCancelButton(_ sender: Any) {
    self.stop()
  }
}

extension KNNewCustomTokenCoordinator: NewTokenViewControllerDelegate {
  func didAddToken(token: ERC20Token, in viewController: NewTokenViewController) {
    self.storage.addCustom(token: token)
    KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
    self.stop()
  }
}
