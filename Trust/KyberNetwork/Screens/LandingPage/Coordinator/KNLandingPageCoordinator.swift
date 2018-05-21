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
    if let wallet = self.keystore.recentlyUsedWallet ?? self.keystore.wallets.first {
      if KNWalletStorage.shared.get(forPrimaryKey: wallet.address.description)?.isBackedUp == false {
        // Open back up wallet if it is created from app and not backed up yet
        self.newWallet = wallet
        self.openBackUpWallet(wallet)
      } else if KNPasscodeUtil.shared.currentPasscode() == nil {
        // In case user imported a wallet and kill the app during settings passcode
        self.newWallet = self.keystore.recentlyUsedWallet ?? self.keystore.wallets.first
        self.passcodeCoordinator.start()
      }
    }
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
    let createPassword = KNCreatePasswordViewController(delegate: self)
    createPassword.modalPresentationStyle = .overCurrentContext
    createPassword.modalTransitionStyle = .crossDissolve
    self.navigationController.topViewController?.present(createPassword, animated: true, completion: nil)
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
    // add new wallet into database in case user exits app
    let walletObject = KNWalletObject(address: wallet.address.description)
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.newWallet = wallet
    self.isCreate = false
    self.keystore.recentlyUsedWallet = wallet
    self.openEnterWalletName(walletObject: walletObject)
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

extension KNLandingPageCoordinator: KNCreatePasswordViewControllerDelegate {
  func createPasswordUserDidFinish(_ password: String) {
    DispatchQueue.global(qos: .userInitiated).async {
      let account = self.keystore.create12wordsAccount(with: password)
      DispatchQueue.main.async {
        let wallet = Wallet(type: WalletType.real(account))
        self.openBackUpWallet(wallet)
      }
    }
  }

  /**
    Open back up wallet view for new wallet created from the app
    Always using 12 words seeds to back up the wallet
   */
  fileprivate func openBackUpWallet(_ wallet: Wallet) {
    let walletObject: KNWalletObject = {
      if let walletObject = KNWalletStorage.shared.get(forPrimaryKey: wallet.address.description) {
        return walletObject
      }
      return KNWalletObject(
        address: wallet.address.description,
        isBackedUp: false
      )
    }()

    let account: Account! = {
      if case .real(let acc) = wallet.type { return acc }
      // Failed to get account from wallet, show enter name
      self.openEnterWalletName(walletObject: walletObject)
      fatalError("Wallet type is not real wallet")
    }()

    self.isCreate = true
    self.newWallet = wallet
    self.keystore.recentlyUsedWallet = wallet
    KNWalletStorage.shared.add(wallets: [walletObject])

    let seedResult = self.keystore.exportMnemonics(account: account)
    if case .success(let mnemonics) = seedResult {
      let seeds = mnemonics.split(separator: " ").map({ return String($0) })
      let backUpVC: KNBackUpWalletViewController = {
        let viewModel = KNBackUpWalletViewModel(seeds: seeds)
        let controller = KNBackUpWalletViewController(viewModel: viewModel)
        controller.delegate = self
        return controller
      }()
      self.navigationController.pushViewController(backUpVC, animated: true)
    } else {
      // Failed to get seeds result, temporary open create name for wallet
      self.openEnterWalletName(walletObject: walletObject)
      fatalError("Can not get seeds from account")
    }
  }
}

extension KNLandingPageCoordinator: KNBackUpWalletViewControllerDelegate {
  func backupWalletViewControllerDidFinish() {
    guard let wallet = self.newWallet else { return }
    let walletObject = KNWalletObject(
      address: wallet.address.description,
      isBackedUp: true
    )
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.openEnterWalletName(walletObject: walletObject)
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
