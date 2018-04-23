// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import IQKeyboardManager

class KNAppCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  let window: UIWindow
  let keystore: Keystore
  var coordinators: [Coordinator] = []
  fileprivate var session: KNSession!
  fileprivate var currentWallet: Wallet!
  fileprivate var balanceCoordinator: KNBalanceCoordinator?

  fileprivate var pendingTransactionStatusCoordinator: KNPendingTransactionStatusCoordinator?

  fileprivate var exchangeCoordinator: KNExchangeTokenCoordinator!
  fileprivate var transferCoordinator: KNTransferTokenCoordinator!
  fileprivate var walletCoordinator: KNWalletCoordinator!
  fileprivate var historyCoordinator: KNHistoryCoordinator!
  fileprivate var settingsCoordinator: KNSettingsCoordinator!

  fileprivate var tabbarController: UITabBarController!

  lazy var splashScreenCoordinator: KNSplashScreenCoordinator = {
    return KNSplashScreenCoordinator()
  }()

  lazy var walletImportingMainCoordinator: KNWalletImportingMainCoordinator = {
    let coordinator = KNWalletImportingMainCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    window: UIWindow,
    keystore: Keystore) {
    self.navigationController = navigationController
    self.window = window
    self.keystore = keystore
    super.init()
    self.window.rootViewController = self.navigationController
    self.window.makeKeyAndVisible()
  }

  deinit {
    self.removeInternalObserveNotification()
    self.removeObserveNotificationFromSession()
  }

  func start() {
    self.addCoordinator(self.splashScreenCoordinator)
    self.splashScreenCoordinator.start()
    self.addCoordinator(self.walletImportingMainCoordinator)
    self.walletImportingMainCoordinator.start()
    if let wallet = self.keystore.wallets.first {
      self.startNewSession(with: wallet)
    }
    self.addInternalObserveNotification()
  }

  func startNewSession(with wallet: Wallet) {
    self.currentWallet = wallet
    self.session = KNSession(keystore: self.keystore, wallet: wallet)
    self.session.startSession()
    self.balanceCoordinator = KNBalanceCoordinator(session: self.session)
    self.balanceCoordinator?.resume()

    self.tabbarController = UITabBarController()
    // Exchange Tab
    self.exchangeCoordinator = {
      let coordinator = KNExchangeTokenCoordinator(
      session: self.session,
      balanceCoordinator: self.balanceCoordinator!
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.exchangeCoordinator)
    self.exchangeCoordinator.start()

    // Transfer Tab
    self.transferCoordinator = {
      let coordinator = KNTransferTokenCoordinator(
        session: self.session,
        balanceCoordinator: self.balanceCoordinator!
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.transferCoordinator)
    self.transferCoordinator.start()

    // Wallet Tab
    self.walletCoordinator = {
      let coordinator = KNWalletCoordinator(
        session: self.session,
        balanceCoordinator: self.balanceCoordinator!
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.walletCoordinator)
    self.walletCoordinator.start()

    // History tab
    self.historyCoordinator = {
      let coordinator = KNHistoryCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.historyCoordinator)
    self.historyCoordinator.start()

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
      self.exchangeCoordinator.navigationController,
      self.transferCoordinator.navigationController,
      self.walletCoordinator.navigationController,
      self.historyCoordinator.navigationController,
      self.settingsCoordinator.navigationController,
    ]
    self.exchangeCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Exchange".toBeLocalised(), image: nil, tag: 0)
    self.transferCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Transfer".toBeLocalised(), image: nil, tag: 1)
    self.walletCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Wallet".toBeLocalised(), image: nil, tag: 2)
    self.historyCoordinator.navigationController.tabBarItem = UITabBarItem(title: "History".toBeLocalised(), image: nil, tag: 3)
    self.settingsCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Settings".toBeLocalised(), image: nil, tag: 4)

    if let topViewController = self.navigationController.topViewController {
      topViewController.addChildViewController(self.tabbarController)
      self.tabbarController.view.frame = topViewController.view.frame
      self.navigationController.topViewController?.view.addSubview(self.tabbarController.view)
      self.tabbarController.didMove(toParentViewController: topViewController)
    }
    // Set select wallet tab
    self.tabbarController.selectedIndex = 2

    self.addObserveNotificationFromSession()
  }

  func stopLastSession() {
    self.removeObserveNotificationFromSession()
    self.session.stopSession()
    self.currentWallet = nil
    self.session = nil
    self.balanceCoordinator?.pause()
    self.balanceCoordinator = nil
    self.tabbarController.view.removeFromSuperview()
    self.tabbarController.removeFromParentViewController()
    // Stop all coordinators in tabs and re-assign to nil
    self.exchangeCoordinator.stop()
    self.exchangeCoordinator = nil
    self.transferCoordinator.stop()
    self.transferCoordinator = nil
    self.walletCoordinator.stop()
    self.walletCoordinator = nil
    self.historyCoordinator.stop()
    self.historyCoordinator = nil
    self.settingsCoordinator.stop()
    self.settingsCoordinator = nil
  }

  fileprivate func addObserveNotificationFromSession() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.transactionStateDidUpdate(_:)),
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
    let ethBalanceName = Notification.Name(kETHBalanceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.ethBalanceDidUpdateNotification(_:)),
      name: ethBalanceName,
      object: nil
    )
    let tokenBalanceName = Notification.Name(kOtherBalanceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenBalancesDidUpdateNotification(_:)),
      name: tokenBalanceName,
      object: nil
    )
  }

  fileprivate func addInternalObserveNotification() {
    let rateTokensName = Notification.Name(kExchangeTokenRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateTokenDidUpdateNotification(_:)),
      name: rateTokensName,
      object: nil)
    let rateUSDName = Notification.Name(kExchangeUSDRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateUSDDidUpdateNotification(_:)),
      name: rateUSDName,
      object: nil
    )
  }

  fileprivate func removeObserveNotificationFromSession() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kETHBalanceDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kOtherBalanceDidUpdateNotificationKey),
      object: nil
    )
  }

  fileprivate func removeInternalObserveNotification() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kExchangeTokenRateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kExchangeUSDRateNotificationKey),
      object: nil
    )
  }

  @objc func exchangeRateTokenDidUpdateNotification(_ sender: Notification) {
    if self.walletCoordinator != nil {
      self.walletCoordinator.exchangeRateDidUpdateNotification(sender)
    }
  }

  @objc func exchangeRateUSDDidUpdateNotification(_ sender: Notification) {
    if self.exchangeCoordinator != nil {
      self.exchangeCoordinator.usdRateDidUpdateNotification(sender)
    }
    if self.transferCoordinator != nil {
      self.transferCoordinator.usdRateDidUpdateNotification(sender)
    }
    if self.walletCoordinator != nil {
      self.walletCoordinator.exchangeRateDidUpdateNotification(sender)
    }
  }

  @objc func ethBalanceDidUpdateNotification(_ sender: Notification) {
    if self.exchangeCoordinator != nil {
      self.exchangeCoordinator.ethBalanceDidUpdateNotification(sender)
    }
    if self.transferCoordinator != nil {
      self.transferCoordinator.ethBalanceDidUpdateNotification(sender)
    }
    if self.walletCoordinator != nil {
      self.walletCoordinator.ethBalanceDidUpdateNotification(sender)
    }
  }

  @objc func tokenBalancesDidUpdateNotification(_ sender: Notification) {
    if self.exchangeCoordinator != nil {
      self.exchangeCoordinator.tokenBalancesDidUpdateNotification(sender)
    }
    if self.transferCoordinator != nil {
      self.transferCoordinator.tokenBalancesDidUpdateNotification(sender)
    }
    if self.walletCoordinator != nil {
      self.walletCoordinator.tokenBalancesDidUpdateNotification(sender)
    }
  }

  @objc func transactionStateDidUpdate(_ sender: Notification) {
    if let txHash = sender.object as? String,
      let transaction = self.session.storage.get(forPrimaryKey: txHash) {

      if self.pendingTransactionStatusCoordinator == nil {
        self.pendingTransactionStatusCoordinator = KNPendingTransactionStatusCoordinator(
          navigationController: self.navigationController,
          transaction: transaction,
          delegate: self
        )
        self.pendingTransactionStatusCoordinator?.start()
      } else {
        self.pendingTransactionStatusCoordinator?.updateTransaction(transaction)
      }
    }
  }
}

// Application state
extension KNAppCoordinator {
  func appDidFinishLaunch() {
    IQKeyboardManager.shared().isEnabled = true
    IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    KNSession.resumeInternalSession()
  }

  func appDidBecomeActive() {
    KNSession.pauseInternalSession()
    KNSession.resumeInternalSession()
    self.balanceCoordinator?.resume()
  }

  func appWillEnterBackground() {
    KNSession.pauseInternalSession()
    self.balanceCoordinator?.pause()
  }
}

extension KNAppCoordinator: KNWalletImportingMainCoordinatorDelegate {
  func walletImportingMainDidImport(wallet: Wallet) {
    self.navigationController.topViewController?.displayLoading(text: "", animated: true)
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
      guard let `self` = self else { return }
      self.navigationController.topViewController?.hideLoading()
      self.startNewSession(with: wallet)
    }
  }
}

extension KNAppCoordinator: KNSessionDelegate {
  func userDidClickExitSession() {
    self.stopLastSession()
  }
}

extension KNAppCoordinator: KNPendingTransactionStatusCoordinatorDelegate {
  func pendingTransactionStatusCoordinatorDidClose() {
    self.pendingTransactionStatusCoordinator = nil
  }
}

extension KNAppCoordinator: KNWalletCoordinatorDelegate {
  func walletCoordinatorDidClickExit() {
    self.stopLastSession()
  }

  func walletCoordinatorDidClickExchange(token: KNToken) {
    self.exchangeCoordinator.appCoordinatorShouldOpenExchangeForToken(token, isReceived: false)
  }

  func walletCoordinatorDidClickTransfer(token: KNToken) {
    if self.transferCoordinator != nil {
      self.transferCoordinator.appCoordinatorShouldOpenTransferForToken(token)
    }
  }

  func walletCoordinatorDidClickReceive(token: KNToken) {
    self.exchangeCoordinator.appCoordinatorShouldOpenExchangeForToken(token, isReceived: true)
  }
}
