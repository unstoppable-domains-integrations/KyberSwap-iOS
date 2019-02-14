// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import Crashlytics

protocol KNCreateWalletCoordinatorDelegate: class {
  func createWalletCoordinatorCancelCreateWallet(_ wallet: Wallet)
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?, name: String?)
  func createWalletCoordinatorDidClose()
}

class KNCreateWalletCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var keystore: Keystore

  fileprivate var newWallet: Wallet?
  fileprivate var name: String?
  weak var delegate: KNCreateWalletCoordinatorDelegate?

  fileprivate var isCreating: Bool = false

  init(
    navigationController: UINavigationController,
    keystore: Keystore,
    newWallet: Wallet?,
    name: String?
    ) {
    self.navigationController = navigationController
    self.keystore = keystore
    self.newWallet = newWallet
    self.name = name
  }

  func start() {
    KNCrashlyticsUtil.logCustomEvent(withName: "create_new_wallet", customAttributes: nil)
    if let wallet = self.newWallet {
      self.isCreating = false
      self.openBackUpWallet(wallet, name: self.name)
    } else {
      self.isCreating = true
      let createWalletVC = KNCreateWalletViewController()
      createWalletVC.loadViewIfNeeded()
      createWalletVC.delegate = self
      createWalletVC.modalTransitionStyle = .crossDissolve
      createWalletVC.modalPresentationStyle = .overCurrentContext
      self.navigationController.present(createWalletVC, animated: true, completion: nil)
    }
  }

  func updateNewWallet(_ wallet: Wallet?, name: String?) {
    self.newWallet = wallet
    self.name = name
  }

  /**
   Open back up wallet view for new wallet created from the app
   Always using 12 words seeds to back up the wallet
   */
  fileprivate func openBackUpWallet(_ wallet: Wallet, name: String?) {
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
      self.delegate?.createWalletCoordinatorDidCreateWallet(self.newWallet, name: name)
      fatalError("Wallet type is not real wallet")
    }()

    self.newWallet = wallet
    self.name = name
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
      self.delegate?.createWalletCoordinatorDidCreateWallet(self.newWallet, name: name)
      fatalError("Can not get seeds from account")
    }
  }
}

extension KNCreateWalletCoordinator: KNBackUpWalletViewControllerDelegate {
  func backupWalletViewControllerDidFinish() {
    guard let wallet = self.newWallet else { return }
    let walletObject = KNWalletObject(
      address: wallet.address.description,
      name: self.name ?? "Untitled",
      isBackedUp: true
    )
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.delegate?.createWalletCoordinatorDidCreateWallet(wallet, name: self.name)
  }

  func backupWalletViewControllerDidConfirmSkipWallet() {
    guard let wallet = self.newWallet else { return }
    let walletObject = KNWalletObject(
      address: wallet.address.description,
      name: self.name ?? "Untitled",
      isBackedUp: false
    )
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.delegate?.createWalletCoordinatorDidCreateWallet(wallet, name: self.name)
  }
}

extension KNCreateWalletCoordinator: KNCreateWalletViewControllerDelegate {
  func createWalletViewController(_ controller: KNCreateWalletViewController, run event: KNCreateWalletViewEvent) {
    switch event {
    case .back:
      self.navigationController.dismiss(animated: true) {
        self.delegate?.createWalletCoordinatorDidClose()
      }
    case .next(let name):
      self.navigationController.dismiss(animated: true) {
        self.navigationController.displayLoading(text: "\(NSLocalizedString("creating", value: "Creating", comment: ""))...", animated: true)
        DispatchQueue.global(qos: .userInitiated).async {
          let account = self.keystore.create12wordsAccount(with: "")
          DispatchQueue.main.async {
            self.navigationController.hideLoading()
            self.navigationController.showSuccessTopBannerMessage(
              with: NSLocalizedString("wallet.created", value: "Wallet Created", comment: ""),
              message: NSLocalizedString("you.have.successfully.created.a.new.wallet", value: "You have successfully created a new wallet!", comment: ""),
              time: 1.5
            )
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5, execute: {
              let wallet = Wallet(type: WalletType.real(account))
              self.name = name
              self.openBackUpWallet(wallet, name: name)
            })
          }
        }
      }
    }
  }
}
