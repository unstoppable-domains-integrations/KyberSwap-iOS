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

    self.tabbarController = UITabBarController()
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
    self.kyberGOCoordinator = {
      return KGOHomePageCoordinator(session: self.session)
    }()
    self.addCoordinator(self.kyberGOCoordinator!)
    self.kyberGOCoordinator?.start()

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
      self.kyberGOCoordinator!.navigationController,
      self.settingsCoordinator.navigationController,
    ]
    self.tabbarController.tabBar.tintColor = UIColor(hex: "00d3a7")
    self.balanceTabCoordinator.navigationController.tabBarItem = UITabBarItem(
      title: "Balance".toBeLocalised(),
      image: UIImage(named: "tabbar_balance_icon"),
      tag: 0
    )
    self.exchangeCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: "KyberSwap".toBeLocalised(),
      image: UIImage(named: "tabbar_kyberswap_icon"),
      tag: 1
    )
    self.kyberGOCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: "KyberGO".toBeLocalised(),
      image: UIImage(named: "tabbar_kybergo_icon"),
      tag: 2
    )
    self.settingsCoordinator.navigationController.tabBarItem = UITabBarItem(
      title: "Settings".toBeLocalised(),
      image: UIImage(named: "tabbar_settings_icon"),
      tag: 3
    )

    if let topViewController = self.navigationController.topViewController {
      topViewController.addChildViewController(self.tabbarController)
      self.tabbarController.view.frame = topViewController.view.frame
      self.navigationController.topViewController?.view.addSubview(self.tabbarController.view)
      self.tabbarController.didMove(toParentViewController: topViewController)
    }
    // Set select wallet tab
    self.tabbarController.selectedIndex = 1

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

    self.tabbarController.view.removeFromSuperview()
    self.tabbarController.removeFromParentViewController()

    // Stop all coordinators in tabs and re-assign to nil
    IEOUserStorage.shared.deleteAll()
    self.exchangeCoordinator?.stop()
    self.exchangeCoordinator = nil
    self.balanceTabCoordinator.stop()
    self.balanceTabCoordinator = nil
    self.kyberGOCoordinator?.stop()
    self.kyberGOCoordinator = nil
    self.settingsCoordinator.stop()
    self.settingsCoordinator = nil
  }

  // Switching account, restart a new session
  func restartNewSession(_ wallet: Wallet) {
    self.removeObserveNotificationFromSession()

    self.balanceCoordinator?.exit()
    self.session.switchSession(wallet)
    self.balanceCoordinator?.restartNewSession(self.session)

    self.exchangeCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.balanceTabCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.kyberGOCoordinator?.updateSession(self.session)
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
