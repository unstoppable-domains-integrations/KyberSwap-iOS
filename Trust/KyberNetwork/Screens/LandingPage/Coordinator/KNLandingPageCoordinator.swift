// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

protocol KNLandingPageCoordinatorDelegate: class {
  func landingPageCoordinator(import wallet: Wallet)
}

class KNLandingPageCoordinator: Coordinator {

  weak var delegate: KNLandingPageCoordinatorDelegate?
  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  fileprivate var newWallet: Wallet?

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

  lazy var passcodeCoordinator: KNPasscodeCoordinator = {
    let coordinator = KNPasscodeCoordinator(
      navigationController: self.navigationController,
      type: .setPasscode
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
  func importWalletCoordinatorDidImport(wallet: Wallet) {
    self.newWallet = wallet
    if self.keystore.wallets.count == 1 {
      KNPasscodeUtil.shared.deletePasscode()
      self.passcodeCoordinator.start()
    } else {
      self.delegate?.landingPageCoordinator(import: wallet)
    }
  }
}

extension KNLandingPageCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel() {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidCreatePasscode() {
    guard let wallet = self.newWallet else { return }
    self.delegate?.landingPageCoordinator(import: wallet)
  }
}
