// Copyright SIX DAY LLC. All rights reserved.

import UIKit

// MARK: This file for handling in session
extension KNAppCoordinator {
  func startNewSession(with wallet: Wallet) {
    self.keystore.recentlyUsedWallet = wallet
    self.currentWallet = wallet
    self.session = KNSession(keystore: self.keystore, wallet: wallet)
    self.session.startSession()
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

    // Exchange Tab
    self.exchangeCoordinator = {
      let coordinator = KNExchangeTokenCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.exchangeCoordinator!)
    self.exchangeCoordinator?.start()

//    // History tab
//    self.historyCoordinator = {
//      let coordinator = KNHistoryCoordinator(
//        session: self.session
//      )
//      coordinator.delegate = self
//      return coordinator
//    }()
//    self.addCoordinator(self.historyCoordinator)
//    self.historyCoordinator.start()

    self.kyberGOCoordinator = {
      return KGOHomePageCoordinator()
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
//      self.historyCoordinator.navigationController,
      self.exchangeCoordinator!.navigationController,
      self.kyberGOCoordinator!.navigationController,
      self.settingsCoordinator.navigationController,
    ]
    self.tabbarController.tabBar.tintColor = UIColor(hex: "5ec2ba")
    self.balanceTabCoordinator.navigationController.tabBarItem = {
      let tabBarItem = UITabBarItem(
        title: "Balance".toBeLocalised(),
        image: UIImage(named: "balance_tab_icon"),
        selectedImage: UIImage(named: "balance_tab_icon")
      )
      tabBarItem.tag = 0
      return tabBarItem
    }()
    self.exchangeCoordinator?.navigationController.tabBarItem = {
      let tabBarItem = UITabBarItem(
        title: "Exchange".toBeLocalised(),
        image: UIImage(named: "exchange_tab_icon"),
        selectedImage: UIImage(named: "exchange_tab_icon")
      )
      tabBarItem.tag = 1
      return tabBarItem
    }()
    self.kyberGOCoordinator?.navigationController.tabBarItem = {
      let tabBarItem = UITabBarItem(
        title: "KyberGO".toBeLocalised(),
        image: UIImage(named: "kybergo_tab_icon"),
        selectedImage: UIImage(named: "kybergo_tab_icon")
      )
      tabBarItem.tag = 2
      return tabBarItem
    }()
//    self.historyCoordinator.navigationController.tabBarItem = {
//      let tabBarItem = UITabBarItem(
//        title: "History".toBeLocalised(),
//        image: UIImage(named: "history_tab_icon"),
//        selectedImage: UIImage(named: "history_tab_icon")
//      )
//      tabBarItem.tag = 2
//      return tabBarItem
//    }()
    self.settingsCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Settings".toBeLocalised(), image: nil, tag: 3)

    if let topViewController = self.navigationController.topViewController {
      topViewController.addChildViewController(self.tabbarController)
      self.tabbarController.view.frame = topViewController.view.frame
      self.navigationController.topViewController?.view.addSubview(self.tabbarController.view)
      self.tabbarController.didMove(toParentViewController: topViewController)
    }
    // Set select wallet tab
    self.tabbarController.selectedIndex = 1

    self.addObserveNotificationFromSession()
  }

  func stopAllSessions() {
    KNPasscodeUtil.shared.deletePasscode()
    self.landingPageCoordinator.navigationController.popToRootViewController(animated: false)
    self.removeObserveNotificationFromSession()

    self.balanceCoordinator?.pause()
    self.balanceCoordinator = nil

    self.session.stopSession()
    KNWalletStorage.shared.deleteAll()

    self.currentWallet = nil
    self.keystore.recentlyUsedWallet = nil
    self.session = nil

    self.tabbarController.view.removeFromSuperview()
    self.tabbarController.removeFromParentViewController()

    // Stop all coordinators in tabs and re-assign to nil
    self.exchangeCoordinator?.stop()
    self.exchangeCoordinator = nil
    self.balanceTabCoordinator.stop()
    self.balanceTabCoordinator = nil
//    self.historyCoordinator.stop()
//    self.historyCoordinator = nil
    self.settingsCoordinator.stop()
    self.settingsCoordinator = nil
  }

  // Switching account, restart a new session
  func restartNewSession(_ wallet: Wallet) {
    self.removeObserveNotificationFromSession()
    self.balanceCoordinator?.pause()
    self.session.switchSession(wallet)
    self.balanceCoordinator?.restartNewSession(self.session)
    // wallet tab
    self.exchangeCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.balanceTabCoordinator.appCoordinatorDidUpdateNewSession(self.session)
//    self.historyCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.settingsCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.tabbarController.selectedIndex = 1
    self.addObserveNotificationFromSession()
  }

  // Remove a wallet
  func removeWallet(_ wallet: Wallet) {
    if self.keystore.wallets.count == 1 {
      self.stopAllSessions()
      return
    }
    // User remove current wallet, switch to another wallet first
    if self.session.wallet == wallet {
      guard let newWallet = self.keystore.wallets.first(where: { $0 != wallet }) else { return }
      self.restartNewSession(newWallet)
    }
    self.session.removeWallet(wallet)
    //TODO: Update UI for each tab
    self.exchangeCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.balanceTabCoordinator.appCoordinatorDidUpdateNewSession(self.session)
//    self.historyCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.settingsCoordinator.appCoordinatorDidUpdateNewSession(self.session)
  }

  func addNewWallet() {
    let addWalletCoordinator = KNAddNewWalletCoordinator(keystore: self.session.keystore)
    addWalletCoordinator.delegate = self
    self.navigationController.present(
      addWalletCoordinator.navigationController,
      animated: false) {
      addWalletCoordinator.start()
    }
  }
}
