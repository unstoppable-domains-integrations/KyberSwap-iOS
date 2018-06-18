// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import IQKeyboardManager
import BigInt

class KNAppCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  let window: UIWindow
  internal var keystore: Keystore
  var coordinators: [Coordinator] = []
  internal var session: KNSession!
  internal var currentWallet: Wallet!
  internal var balanceCoordinator: KNBalanceCoordinator?

  internal var exchangeCoordinator: KNExchangeTokenCoordinator?
  internal var balanceTabCoordinator: KNBalanceTabCoordinator!
  internal var historyCoordinator: KNHistoryCoordinator!
  internal var settingsCoordinator: KNSettingsCoordinator!

  internal var kyberGOCoordinator: KGOHomePageCoordinator?

  internal var tabbarController: UITabBarController!
  internal var transactionStatusCoordinator: KNTransactionStatusCoordinator!

  lazy var splashScreenCoordinator: KNSplashScreenCoordinator = {
    return KNSplashScreenCoordinator()
  }()

  lazy var authenticationCoordinator: KNPasscodeCoordinator = {
    return KNPasscodeCoordinator(type: .authenticate)
  }()

  lazy var landingPageCoordinator: KNLandingPageCoordinator = {
    let coordinator = KNLandingPageCoordinator(
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
