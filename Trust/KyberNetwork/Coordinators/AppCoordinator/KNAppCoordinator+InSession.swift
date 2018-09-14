// Copyright SIX DAY LLC. All rights reserved.

import UIKit

// MARK: This file for handling in session
extension KNAppCoordinator {
  func startNewSession(with wallet: Wallet) {
    self.keystore.recentlyUsedWallet = wallet
    self.currentWallet = wallet
    self.session = KNSession(keystore: self.keystore, wallet: wallet)
    self.session.startSession()
    self.balanceCoordinator?.exit()
    self.balanceCoordinator = nil
    self.balanceCoordinator = KNBalanceCoordinator(session: self.session)
    self.balanceCoordinator?.resume()

    self.tabbarController = KNTabBarController()
    // Balance Tab
    self.balanceTabCoordinator = {
      let coordinator = KNBalanceTabCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.balanceTabCoordinator)
    self.balanceTabCoordinator.start()

    // KyberSwap Tab
    self.exchangeCoordinator = {
      let coordinator = KNExchangeTokenCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.exchangeCoordinator!)
    self.exchangeCoordinator?.start()

    // KyberGO Tab
    self.profileCoordinator = {
      return KNProfileHomeCoordinator(session: self.session)
    }()
    self.addCoordinator(self.profileCoordinator!)
    self.profileCoordinator?.start()

    // Settings tab
    self.settingsCoordinator = {
      let coordinator = KNSettingsCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.settingsCoordinator)
    self.settingsCoordinator.start()

    self.tabbarController.viewControllers = [
      self.balanceTabCoordinator.navigationController,
      self.exchangeCoordinator!.navigationController,
      self.profileCoordinator!.navigationController,
      self.settingsCoordinator.navigationController,
    ]
    self.tabbarController.tabBar.tintColor = UIColor.Kyber.fire
    self.balanceTabCoordinator.navigationController.tabBarItem = UITabBarItem(
      title: "Balance".toBeLocalised(),
      image: UIImage(named: "tabbar_balance_icon"),
      selectedImage: UIImage(named: "tabbar_balance_icon")
    )
    self.balanceTabCoordinator.navigationController.tabBarItem.tag = 0
    self.exchangeCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: "KyberSwap".toBeLocalised(),
      image: UIImage(named: "tabbar_kyberswap_icon"),
      selectedImage: UIImage(named: "tabbar_kyberswap_icon")
    )
    self.exchangeCoordinator?.navigationController.tabBarItem.tag = 1
    self.profileCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: "Profile".toBeLocalised(),
      image: UIImage(named: "tabbar_profile_icon"),
      selectedImage: UIImage(named: "tabbar_profile_icon")
    )
    self.profileCoordinator?.navigationController.tabBarItem.tag = 2
    self.settingsCoordinator.navigationController.tabBarItem = UITabBarItem(
      title: "Settings".toBeLocalised(),
      image: UIImage(named: "tabbar_settings_icon"),
      selectedImage: UIImage(named: "tabbar_settings_icon")
    )
    self.settingsCoordinator.navigationController.tabBarItem.tag = 3
    self.navigationController.pushViewController(self.tabbarController, animated: true) {
      self.tabbarController.selectedIndex = 1
    }

    self.addObserveNotificationFromSession()
    self.updateLocalData()
  }

  func stopAllSessions() {
    KNPasscodeUtil.shared.deletePasscode()
    self.landingPageCoordinator.navigationController.popToRootViewController(animated: false)
    self.removeObserveNotificationFromSession()

    self.balanceCoordinator?.exit()
    self.balanceCoordinator = nil

    self.session.stopSession()
    KNWalletStorage.shared.deleteAll()

    self.currentWallet = nil
    self.keystore.recentlyUsedWallet = nil
    self.session = nil

    self.navigationController.popToRootViewController(animated: true)

    // Stop all coordinators in tabs and re-assign to nil
    self.exchangeCoordinator?.stop()
    self.exchangeCoordinator = nil
    self.balanceTabCoordinator.stop()
    self.balanceTabCoordinator = nil
    self.profileCoordinator?.stop()
    self.profileCoordinator = nil
    self.settingsCoordinator.stop()
    self.settingsCoordinator = nil
    IEOUserStorage.shared.signedOut()
    self.tabbarController = nil
  }

  // Switching account, restart a new session
  func restartNewSession(_ wallet: Wallet) {
    self.removeObserveNotificationFromSession()

    self.balanceCoordinator?.exit()
    self.session.switchSession(wallet)
    self.balanceCoordinator?.restartNewSession(self.session)

    self.exchangeCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.balanceTabCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.profileCoordinator?.updateSession(self.session)
    self.settingsCoordinator.appCoordinatorDidUpdateNewSession(self.session)

    self.tabbarController.selectedIndex = 1
    self.addObserveNotificationFromSession()
    self.updateLocalData()
  }

  // Remove a wallet
  func removeWallet(_ wallet: Wallet) {
    if self.keystore.wallets.count == 1 {
      self.stopAllSessions()
      return
    }
    // User remove current wallet, switch to another wallet first
    let isRemovingCurrentWallet: Bool = self.session.wallet == wallet
    if isRemovingCurrentWallet {
      guard let newWallet = self.keystore.wallets.first(where: { $0 != wallet }) else { return }
      self.restartNewSession(newWallet)
    }
    self.balanceCoordinator?.exit()
    if self.session.removeWallet(wallet) {
      self.balanceCoordinator?.restartNewSession(self.session)
      self.exchangeCoordinator?.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: isRemovingCurrentWallet
      )
      self.balanceTabCoordinator.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: isRemovingCurrentWallet
      )
      self.settingsCoordinator.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: isRemovingCurrentWallet
      )
    } else {
      self.balanceCoordinator?.restartNewSession(self.session)
      self.navigationController.showErrorTopBannerMessage(with: "Error", message: "Something went wrong. Can not remove the wallet")
    }
  }

  func addNewWallet() {
    if self.session.keystore.wallets.count == 3 {
      self.navigationController.showWarningTopBannerMessage(
        with: "",
        message: "You can only add at most 3 wallets".toBeLocalised(),
        time: 2.5
      )
      return
    }
    let addWalletCoordinator = KNAddNewWalletCoordinator(keystore: self.session.keystore)
    addWalletCoordinator.delegate = self
    self.navigationController.present(
      addWalletCoordinator.navigationController,
      animated: false) {
      addWalletCoordinator.start()
    }
  }

  fileprivate func updateLocalData() {
    self.tokenBalancesDidUpdateNotification(nil)
    self.ethBalanceDidUpdateNotification(nil)
    self.exchangeRateTokenDidUpdateNotification(nil)
    self.tokenObjectListDidUpdate(nil)
    self.tokenTransactionListDidUpdate(nil)
  }
}
