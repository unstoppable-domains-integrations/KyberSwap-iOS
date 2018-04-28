// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNNewCustomTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  let storage: KNTokenStorage
  let token: ERC20Token?
  var coordinators: [Coordinator] = []

//  lazy var rootViewController: KNNewCustomTokenViewController = {
//    let controller = KNNewCustomTokenViewController(
//      viewModel: KNNewCustomTokenViewModel(token: self.token),
//      delegate: self
//    )
//    return controller
//  }()

  lazy var rootViewController: NewTokenViewController = {
    let newTokenVC = NewTokenViewController(token: .none)
    newTokenVC.delegate = self
    return newTokenVC
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
    let navController = UINavigationController(rootViewController: self.rootViewController)
//    navController.applyStyle()
    self.navigationController.present(navController, animated: true, completion: nil)
  }

  func stop() {
    self.navigationController.dismiss(animated: true, completion: nil)
  }
}

//extension KNNewCustomTokenCoordinator: KNNewCustomTokenViewControllerDelegate {
//  func didCancel(in viewController: KNNewCustomTokenViewController) {
//    self.stop()
//  }
//
//  func didAddToken(_ token: ERC20Token, in viewController: KNNewCustomTokenViewController) {
//    self.storage.addCustom(token: token)
//    KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
//    self.stop()
//  }
//}

extension KNNewCustomTokenCoordinator: NewTokenViewControllerDelegate {
  func didAddToken(token: ERC20Token, in viewController: NewTokenViewController) {
    self.storage.addCustom(token: token)
    KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
    self.stop()
  }
}
