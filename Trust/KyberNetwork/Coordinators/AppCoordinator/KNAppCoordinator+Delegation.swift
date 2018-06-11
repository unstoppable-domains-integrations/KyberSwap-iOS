// Copyright SIX DAY LLC. All rights reserved.

import UIKit

// MARK: Landing Page Coordinator Delegate
extension KNAppCoordinator: KNLandingPageCoordinatorDelegate {
  func landingPageCoordinator(import wallet: Wallet) {
    self.startNewSession(with: wallet)
  }
}

// MARK: Wallet Importing Main Coordinator Delegate
extension KNAppCoordinator: KNWalletImportingMainCoordinatorDelegate {
  func walletImportingMainDidImport(wallet: Wallet) {
    let walletObject = KNWalletObject(address: wallet.address.description)
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.navigationController.topViewController?.displayLoading(text: "", animated: true)
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
      guard let `self` = self else { return }
      self.navigationController.topViewController?.hideLoading()
      self.startNewSession(with: wallet)
    }
  }
}

// MARK: Session Delegate
extension KNAppCoordinator: KNSessionDelegate {
  func userDidClickExitSession() {
    let alertController = UIAlertController(
      title: "Exit".toBeLocalised(),
      message: "Do you want to exit and remove all wallets from the app?".toBeLocalised(),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
      self.stopAllSessions()
    }))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}

// MARK: Exchange Token Coordinator Delegate
extension KNAppCoordinator: KNExchangeTokenCoordinatorDelegate {
  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else { return }
    if let recentWallet = self.keystore.recentlyUsedWallet, recentWallet == wallet { return }
    self.restartNewSession(wallet)
  }

  func exchangeTokenCoordinatorDidSelectAddWallet() {
    self.addNewWallet()
  }
}

// MARK: Settings Coordinator Delegate
extension KNAppCoordinator: KNSettingsCoordinatorDelegate {
  func settingsCoordinatorUserDidSelectExit() {
    self.userDidClickExitSession()
  }

  func settingsCoordinatorUserDidSelectNewWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }

  func settingsCoordinatorUserDidRemoveWallet(_ wallet: Wallet) {
    self.removeWallet(wallet)
  }
}

// MARK: Balance Tab Coordinator Delegate
extension KNAppCoordinator: KNBalanceTabCoordinatorDelegate {
  func balanceTabCoordinatorShouldOpenExchange(for tokenObject: TokenObject, isReceived: Bool) {
    self.exchangeCoordinator?.appCoordinatorShouldOpenExchangeForToken(tokenObject, isReceived: isReceived)
    self.tabbarController.selectedIndex = 0
  }

  func balanceTabCoordinatorDidSelect(walletObject: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == walletObject.address.lowercased() }) else { return }
    self.restartNewSession(wallet)
  }

  func balancetabCoordinatorDidSelectAddWallet() {
    self.addNewWallet()
  }
}

// MARK: Transaction Status Delegate
extension KNAppCoordinator: KNTransactionStatusCoordinatorDelegate {
  func transactionStatusCoordinatorDidClose() {
    self.transactionStatusCoordinator = nil
  }
}

// MARK: Add wallet coordinator delegate
extension KNAppCoordinator: KNAddNewWalletCoordinatorDelegate {
  func addNewWalletCoordinator(add wallet: Wallet) {
    self.startNewSession(with: wallet)
  }
}
