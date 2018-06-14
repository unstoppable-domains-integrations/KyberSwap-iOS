// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import TrustKeystore

protocol KNLandingPageCoordinatorDelegate: class {
  func landingPageCoordinator(import wallet: Wallet)
}

/**
 Flow:
 1. Create Wallet:
  - Enter password
  - Backup 12 words seed for new wallet
  - Testing backup
  - Enter wallet name
  - Enter passcode (if it is the first wallet)
 2. Import Wallet:
  - JSON/Private Key/Seeds
  - Enter wallet name
  - Enter passcode (if it is the first wallet)
 */
class KNLandingPageCoordinator: Coordinator {

  weak var delegate: KNLandingPageCoordinatorDelegate?
  let navigationController: UINavigationController
  var keystore: Keystore
  var coordinators: [Coordinator] = []

  fileprivate var newWallet: Wallet?
  fileprivate var isCreate: Bool = false

  lazy var rootViewController: KNLandingPageViewController = {
    let controller = KNLandingPageViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var createWalletCoordinator: KNCreateWalletCoordinator = {
    let coordinator = KNCreateWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore,
      newWallet: self.newWallet
    )
    coordinator.delegate = self
    return coordinator
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
    if self.keystore.wallets.isEmpty && KNPasscodeUtil.shared.currentPasscode() != nil {
      // In case user delete the app, wallets are removed but passcode is still save in keychain
      KNPasscodeUtil.shared.deletePasscode()
    }
    if let wallet = self.keystore.recentlyUsedWallet ?? self.keystore.wallets.first {
      if KNWalletStorage.shared.get(forPrimaryKey: wallet.address.description)?.isBackedUp == false {
        // Open back up wallet if it is created from app and not backed up yet
        self.newWallet = wallet
        self.isCreate = true
        self.createWalletCoordinator.updateNewWallet(wallet)
        self.createWalletCoordinator.start()
      } else if KNPasscodeUtil.shared.currentPasscode() == nil {
        // In case user imported a wallet and kill the app during settings passcode
        self.newWallet = self.keystore.recentlyUsedWallet ?? self.keystore.wallets.first
        self.passcodeCoordinator.start()
      }
    }
  }

  fileprivate func addNewWallet(_ wallet: Wallet, isCreate: Bool) {
    // add new wallet into database in case user exits app
    let walletObject = KNWalletObject(address: wallet.address.description)
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.newWallet = wallet
    self.isCreate = isCreate
    self.keystore.recentlyUsedWallet = wallet
    self.openEnterWalletName(walletObject: walletObject)
  }

  // Enter wallet name (optional) for each imported/created wallet
  // After name will be settings passcode if it is the first added wallet
  fileprivate func openEnterWalletName(walletObject: KNWalletObject) {
    let enterNameVC: KNEnterWalletNameViewController = {
      let viewModel = KNEnterWalletNameViewModel(walletObject: walletObject)
      let controller = KNEnterWalletNameViewController(viewModel: viewModel)
      controller.delegate = self
      controller.modalPresentationStyle = .overFullScreen
      controller.modalTransitionStyle = .crossDissolve
      return controller
    }()
    self.navigationController.topViewController?.present(enterNameVC, animated: true, completion: nil)
  }
}

extension KNLandingPageCoordinator: KNLandingPageViewControllerDelegate {
  func landingPageCreateWalletPressed(sender: KNLandingPageViewController) {
    self.createWalletCoordinator.updateNewWallet(nil)
    self.createWalletCoordinator.start()
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
    self.addNewWallet(wallet, isCreate: false)
  }

  func importWalletCoordinatorDidClose() {
  }
}

extension KNLandingPageCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel() {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidCreatePasscode() {
    guard let wallet = self.newWallet else { return }
    self.navigationController.topViewController?.displayLoading()
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
      self.navigationController.topViewController?.hideLoading()
      self.delegate?.landingPageCoordinator(import: wallet)
    }
  }
}

extension KNLandingPageCoordinator: KNCreateWalletCoordinatorDelegate {
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?) {
    guard let wallet = wallet else { return }
    self.addNewWallet(wallet, isCreate: true)
  }
}

extension KNLandingPageCoordinator: KNEnterWalletNameViewControllerDelegate {
  func enterWalletNameDidNext(sender: KNEnterWalletNameViewController, walletObject: KNWalletObject) {
    KNWalletStorage.shared.add(wallets: [walletObject])
    guard let wallet = self.newWallet else { return }
    if self.keystore.wallets.count == 1 {
      KNPasscodeUtil.shared.deletePasscode()
      self.passcodeCoordinator.start()
    } else {
      self.delegate?.landingPageCoordinator(import: wallet)
    }
  }
}
