// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import IQKeyboardManager
import BigInt

class KNAppCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  let window: UIWindow
  fileprivate var keystore: Keystore
  var coordinators: [Coordinator] = []
  fileprivate var session: KNSession!
  fileprivate var currentWallet: Wallet!
  fileprivate var balanceCoordinator: KNBalanceCoordinator?

  fileprivate var exchangeCoordinator: KNExchangeTokenCoordinator?
  fileprivate var transferCoordinator: KNTransferTokenCoordinator?
  fileprivate var balanceTabCoordinator: KNBalanceTabCoordinator!
  fileprivate var historyCoordinator: KNHistoryCoordinator!
  fileprivate var settingsCoordinator: KNSettingsCoordinator!

  fileprivate var tabbarController: UITabBarController!

  lazy var splashScreenCoordinator: KNSplashScreenCoordinator = {
    return KNSplashScreenCoordinator()
  }()

  lazy var authenticationCoordinator: KNPasscodeCoordinator = {
    return KNPasscodeCoordinator(type: .authenticate)
  }()

  lazy var walletImportingMainCoordinator: KNWalletImportingMainCoordinator = {
    let coordinator = KNWalletImportingMainCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var landingPageCoordinator: KNLandingPageCoordinator = {
    let coordinator = KNLandingPageCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  fileprivate var transactionStatusCoordinator: KNTransactionStatusCoordinator!

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
    KNSupportedTokenStorage.shared.addLocalSupportedTokens()
    self.addCoordinator(self.landingPageCoordinator)
    self.landingPageCoordinator.start()
    // For security, should always have passcode protection when user has imported wallets
    // In case user created a new wallet, it should be backed up
    if let wallet = self.keystore.recentlyUsedWallet ?? self.keystore.wallets.first,
      KNPasscodeUtil.shared.currentPasscode() != nil, KNWalletStorage.shared.get(forPrimaryKey: wallet.address.description)?.isBackedUp == true {
      self.startNewSession(with: wallet)
    }
    self.addInternalObserveNotification()
  }

  //swiftlint:disable function_body_length
  func startNewSession(with wallet: Wallet) {
    self.keystore.recentlyUsedWallet = wallet
    self.currentWallet = wallet
    self.session = KNSession(keystore: self.keystore, wallet: wallet)
    self.session.startSession()
    self.balanceCoordinator = KNBalanceCoordinator(session: self.session)
    self.balanceCoordinator?.resume()

    self.tabbarController = UITabBarController()
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

    // Transfer Tab
    self.transferCoordinator = {
      let coordinator = KNTransferTokenCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.transferCoordinator!)
    self.transferCoordinator?.start()

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
      self.exchangeCoordinator!.navigationController,
      self.transferCoordinator!.navigationController,
      self.balanceTabCoordinator.navigationController,
      self.historyCoordinator.navigationController,
      self.settingsCoordinator.navigationController,
    ]
    self.tabbarController.tabBar.tintColor = UIColor(hex: "5ec2ba")
    self.exchangeCoordinator?.navigationController.tabBarItem = {
      let tabBarItem = UITabBarItem(
        title: "Exchange".toBeLocalised(),
        image: UIImage(named: "exchange_tab_icon"),
        selectedImage: UIImage(named: "exchange_tab_icon")
      )
      tabBarItem.tag = 0
      return tabBarItem
    }()
    self.transferCoordinator?.navigationController.tabBarItem = {
      let tabBarItem = UITabBarItem(
        title: "Send".toBeLocalised(),
        image: UIImage(named: "send_tab_icon"),
        selectedImage: UIImage(named: "send_tab_icon")
      )
      tabBarItem.tag = 1
      return tabBarItem
    }()
    self.balanceTabCoordinator.navigationController.tabBarItem = {
      let tabBarItem = UITabBarItem(
        title: "Balance".toBeLocalised(),
        image: UIImage(named: "balance_tab_icon"),
        selectedImage: UIImage(named: "balance_tab_icon")
      )
      tabBarItem.tag = 2
      return tabBarItem
    }()
    self.historyCoordinator.navigationController.tabBarItem = {
      let tabBarItem = UITabBarItem(
        title: "History".toBeLocalised(),
        image: UIImage(named: "history_tab_icon"),
        selectedImage: UIImage(named: "history_tab_icon")
      )
      tabBarItem.tag = 3
      return tabBarItem
    }()
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
    self.transferCoordinator?.stop()
    self.transferCoordinator = nil
    self.balanceTabCoordinator.stop()
    self.balanceTabCoordinator = nil
    self.historyCoordinator.stop()
    self.historyCoordinator = nil
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
    self.transferCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.balanceTabCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.historyCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.settingsCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.tabbarController.selectedIndex = 2
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
    self.transferCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.balanceTabCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.historyCoordinator.appCoordinatorDidUpdateNewSession(self.session)
    self.settingsCoordinator.appCoordinatorDidUpdateNewSession(self.session)
  }
}

// MARK: Notification
extension KNAppCoordinator {
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
    let tokenTxListName = Notification.Name(kTokenTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenTransactionListDidUpdate(_:)),
      name: tokenTxListName,
      object: nil
    )
    let tokenObjectListName = Notification.Name(kTokenObjectListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: tokenObjectListName,
      object: nil
    )
    let coinTickerName = Notification.Name(kCoinTickersDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.coinTickerDidUpdate(_:)),
      name: coinTickerName,
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
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: supportedTokensName,
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
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTokenTransactionListDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTokenObjectListDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kCoinTickersDidUpdateNotificationKey),
      object: self
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
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: supportedTokensName,
      object: nil
    )
  }

  @objc func exchangeRateTokenDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let balanceCoordinator = self.balanceCoordinator else { return }

    self.balanceTabCoordinator.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: balanceCoordinator.totalBalanceInUSD,
      totalBalanceInETH: balanceCoordinator.totalBalanceInETH
    )
  }

  @objc func exchangeRateUSDDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let balanceCoordinator = self.balanceCoordinator else { return }
    let totalUSD: BigInt = balanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = balanceCoordinator.totalBalanceInETH

    self.exchangeCoordinator?.appCoordinatorUSDRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )
    self.transferCoordinator?.appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: totalUSD)
    self.balanceTabCoordinator.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )
  }

  @objc func ethBalanceDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let balanceCoordinator = self.balanceCoordinator else { return }
    let totalUSD: BigInt = balanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = balanceCoordinator.totalBalanceInETH
    let ethBalance: Balance = balanceCoordinator.ethBalance

    self.exchangeCoordinator?.appCoordinatorETHBalanceDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      ethBalance: ethBalance
    )
    self.transferCoordinator?.appCoordinatorETHBalanceDidUpdate(
      totalBalanceInUSD: totalUSD,
      ethBalance: ethBalance
    )
    self.balanceTabCoordinator.appCoordinatorETHBalanceDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      ethBalance: ethBalance
    )
  }

  @objc func tokenBalancesDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let balanceCoordinator = self.balanceCoordinator else { return }
    let totalUSD: BigInt = balanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = balanceCoordinator.totalBalanceInETH
    let otherTokensBalance: [String: Balance] = balanceCoordinator.otherTokensBalance

    self.exchangeCoordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )
    self.transferCoordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      otherTokensBalance: otherTokensBalance
    )
    self.balanceTabCoordinator.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )
  }

  @objc func transactionStateDidUpdate(_ sender: Notification) {
    if self.session == nil { return }
    let transaction: Transaction? = {
      if let txHash = sender.object as? String {
        return self.session.transactionStorage.get(forPrimaryKey: txHash)
      }
      return nil
    }()
    let error: Error? = sender.object as? Error
    if self.transactionStatusCoordinator == nil {
      self.transactionStatusCoordinator = KNTransactionStatusCoordinator(
        navigationController: self.navigationController,
        transaction: transaction,
        delegate: self
      )
      self.transactionStatusCoordinator.start()
    }
    self.transactionStatusCoordinator.updateTransaction(transaction, error: error)
    // Force load new token transactions to faster updating history view
    if let tran = transaction, tran.state == .completed {
      self.session.transacionCoordinator?.forceFetchTokenTransactions()
    }
  }

  @objc func tokenTransactionListDidUpdate(_ sender: Notification) {
    if self.session == nil { return }
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  @objc func tokenObjectListDidUpdate(_ sender: Notification) {
    if self.session == nil { return }
    self.session.tokenStorage.addKyberSupportedTokens()
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
    self.balanceTabCoordinator.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.exchangeCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.transferCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  @objc func coinTickerDidUpdate(_ sender: Notification) {
    if self.session == nil { return }
    self.balanceTabCoordinator.appCoordinatorCoinTickerDidUpdate()
  }
}

// Application state
extension KNAppCoordinator {
  func appDidFinishLaunch() {
    self.splashScreenCoordinator.start()
    self.authenticationCoordinator.start()
    IQKeyboardManager.shared().isEnabled = true
    IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    KNSession.resumeInternalSession()
    KNCoinTickerCoordinator.shared.start()
  }

  func appDidBecomeActive() {
    KNSession.pauseInternalSession()
    KNSession.resumeInternalSession()
    self.balanceCoordinator?.resume()
    self.splashScreenCoordinator.stop()
  }

  func appWillEnterForeground() {
    self.authenticationCoordinator.start()
    KNCoinTickerCoordinator.shared.start()
  }

  func appDidEnterBackground() {
    self.splashScreenCoordinator.stop()
    KNSession.pauseInternalSession()
    self.balanceCoordinator?.pause()
    KNCoinTickerCoordinator.shared.stop()
  }
}

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
    let alertController = UIAlertController(title: "Exit".toBeLocalised(), message: "Do you want to exit and remove all wallets from the app?".toBeLocalised(), preferredStyle: .alert)
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
}

// MARK: Wallet Coordinator Delegate
extension KNAppCoordinator: KNWalletCoordinatorDelegate {
  func walletCoordinatorDidClickExit() {
    self.userDidClickExitSession()
  }

  func walletCoordinatorDidClickExchange(token: TokenObject) {
    self.exchangeCoordinator?.appCoordinatorShouldOpenExchangeForToken(token, isReceived: false)
  }

  func walletCoordinatorDidClickTransfer(token: TokenObject) {
    self.transferCoordinator?.appCoordinatorShouldOpenTransferForToken(token)
  }

  func walletCoordinatorDidClickReceive(token: TokenObject) {
    self.exchangeCoordinator?.appCoordinatorShouldOpenExchangeForToken(token, isReceived: true)
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
  func balanceTabCoordinatorShouldOpenExchange(for tokenObject: TokenObject) {
    self.exchangeCoordinator?.appCoordinatorShouldOpenExchangeForToken(tokenObject)
    self.tabbarController.selectedIndex = 0
  }

  func balanceTabCoordinatorShouldOpenSend(for tokenObject: TokenObject) {
    self.transferCoordinator?.appCoordinatorShouldOpenTransferForToken(tokenObject)
    self.tabbarController.selectedIndex = 1
  }

  func balanceTabCoordinatorDidSelect(walletObject: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == walletObject.address.lowercased() }) else { return }
    self.restartNewSession(wallet)
  }
}

// MARK: Transaction Status Delegate
extension KNAppCoordinator: KNTransactionStatusCoordinatorDelegate {
  func transactionStatusCoordinatorDidClose() {
    self.transactionStatusCoordinator = nil
  }
}
