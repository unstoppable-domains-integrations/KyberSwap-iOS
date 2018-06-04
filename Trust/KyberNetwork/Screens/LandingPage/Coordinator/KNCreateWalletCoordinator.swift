// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore

protocol KNCreateWalletCoordinatorDelegate: class {
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?)
}

class KNCreateWalletCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var keystore: Keystore

  fileprivate var newWallet: Wallet?
  weak var delegate: KNCreateWalletCoordinatorDelegate?

  init(
    navigationController: UINavigationController,
    keystore: Keystore,
    newWallet: Wallet?
    ) {
    self.navigationController = navigationController
    self.keystore = keystore
    self.newWallet = newWallet
  }

  func start() {
    if let wallet = self.newWallet {
      self.openBackUpWallet(wallet)
    } else {
      let password = "1234567890"//PasswordGenerator.generateRandom()
      DispatchQueue.global(qos: .userInitiated).async {
        let account = self.keystore.create12wordsAccount(with: password)
        DispatchQueue.main.async {
          let wallet = Wallet(type: WalletType.real(account))
          self.openBackUpWallet(wallet)
        }
      }
    }
  }

  func updateNewWallet(_ wallet: Wallet?) {
    self.newWallet = wallet
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
      self.delegate?.createWalletCoordinatorDidCreateWallet(self.newWallet)
      fatalError("Wallet type is not real wallet")
    }()

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
      self.delegate?.createWalletCoordinatorDidCreateWallet(self.newWallet)
      fatalError("Can not get seeds from account")
    }
  }
}

extension KNCreateWalletCoordinator: KNBackUpWalletViewControllerDelegate {
  func backupWalletViewControllerDidFinish() {
    guard let wallet = self.newWallet else { return }
    let walletObject = KNWalletObject(
      address: wallet.address.description,
      isBackedUp: true
    )
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.delegate?.createWalletCoordinatorDidCreateWallet(wallet)
  }
}
