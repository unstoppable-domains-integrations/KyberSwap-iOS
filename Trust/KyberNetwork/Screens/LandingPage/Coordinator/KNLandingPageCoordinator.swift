// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

protocol KNLandingPageCoordinatorDelegate: class {
  func landingPageCoordinator(import wallet: Wallet, name: String)
}

class KNLandingPageCoordinator: Coordinator {

  weak var delegate: KNLandingPageCoordinatorDelegate?
  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNLandingPageViewController = {
    let controller = KNLandingPageViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var importWalletCoordinator: KNImportWalletCoordinator = {
    let coordinator = KNImportWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    keystore: Keystore
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.keystore = keystore
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }
}

extension KNLandingPageCoordinator: KNLandingPageViewControllerDelegate {
  func landingPageCreateWalletPressed(sender: KNLandingPageViewController) {
    // TODO: Implement it
    self.rootViewController.showWarningTopBannerMessage(with: "TODO", message: "Todolist")
  }

  func landingPageImportWalletPressed(sender: KNLandingPageViewController) {
    self.importWalletCoordinator.start()
  }

  func landingPageTermAndConditionPressed(sender: KNLandingPageViewController) {
    guard let url = URL(string: "https://home.kyber.network/assets/tac.pdf") else { return }
    let safariVC: SFSafariViewController = {
      return SFSafariViewController(url: url)
    }()
    self.navigationController.topViewController?.present(safariVC, animated: true, completion: nil)
  }
}

extension KNLandingPageCoordinator: KNImportWalletCoordinatorDelegate {
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String) {
    self.delegate?.landingPageCoordinator(import: wallet, name: name)
  }
}
