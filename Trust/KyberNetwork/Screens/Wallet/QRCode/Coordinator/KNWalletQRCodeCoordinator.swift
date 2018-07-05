// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

class KNWalletQRCodeCoordinator: Coordinator {

  let navigationController: UINavigationController
  let walletObject: KNWalletObject
  var coordinators: [Coordinator] = []

  init(
    navigationController: UINavigationController,
    walletObject: KNWalletObject
    ) {
    self.navigationController = navigationController
    self.walletObject = walletObject
  }

  lazy var viewModel: KNWalletQRCodeViewModel = {
    return KNWalletQRCodeViewModel(wallet: self.walletObject)
  }()

  lazy var rootViewController: KNWalletQRCodeViewController = {
    let controller = KNWalletQRCodeViewController(viewModel: self.viewModel)
    controller.loadViewIfNeeded()
    return controller
  }()

  func start() {
    let navController: UINavigationController = {
      let navController = UINavigationController(rootViewController: self.rootViewController)
      navController.applyStyle()
      return navController
    }()
    self.navigationController.present(navController, animated: true, completion: nil)
  }
}
