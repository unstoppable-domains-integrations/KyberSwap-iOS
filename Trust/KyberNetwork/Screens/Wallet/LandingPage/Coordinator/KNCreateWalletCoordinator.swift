// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore

protocol KNCreateWalletCoordinatorDelegate: class {
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?, name: String?)
}

class KNCreateWalletCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var keystore: Keystore

  fileprivate var newWallet: Wallet?
  fileprivate var name: String?
  weak var delegate: KNCreateWalletCoordinatorDelegate?

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
    if let wallet = self.newWallet {
      self.openBackUpWallet(wallet, name: self.name)
    } else {
      DispatchQueue.global(qos: .userInitiated).async {
        let account = self.keystore.create12wordsAccount(with: "")
        DispatchQueue.main.async {
          let wallet = Wallet(type: WalletType.real(account))
          self.openBackUpWallet(wallet, name: self.name)
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
}
