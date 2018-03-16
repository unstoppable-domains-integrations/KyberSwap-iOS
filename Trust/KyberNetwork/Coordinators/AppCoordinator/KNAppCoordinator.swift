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

  func start() {
    self.addCoordinator(self.splashScreenCoordinator)
    self.splashScreenCoordinator.start()
    self.addCoordinator(self.walletImportingMainCoordinator)
    self.walletImportingMainCoordinator.start()
    if let wallet = self.keystore.wallets.first {
      self.startNewSession(with: wallet)
    }
  }

  func startNewSession(with wallet: Wallet) {
    self.currentWallet = wallet
    self.session = KNSession(keystore: self.keystore, wallet: wallet)
    self.session.startSession()
    self.balanceCoordinator = KNBalanceCoordinator(session: self.session)
    self.balanceCoordinator?.resume()

    let tabbarController = UITabBarController()
    let exchangeCoordinator: KNExchangeTokenCoordinator = {
      let coordinator = KNExchangeTokenCoordinator(
      session: self.session,
      balanceCoordinator: self.balanceCoordinator!
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(exchangeCoordinator)
    exchangeCoordinator.start()

    let transferVC = KNBaseViewController()
    let transferNav = UINavigationController(rootViewController: transferVC)

    let walletVC = KNBaseViewController()
    let walletNav = UINavigationController(rootViewController: walletVC)

    tabbarController.viewControllers = [
      exchangeCoordinator.navigationController,
      transferNav,
      walletNav,
    ]
    exchangeCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Exchange", image: nil, tag: 0)
    transferNav.tabBarItem = UITabBarItem(title: "Transfer", image: nil, tag: 1)
    walletNav.tabBarItem = UITabBarItem(title: "Wallet", image: nil, tag: 2)

    self.navigationController.present(tabbarController, animated: true, completion: nil)
  }

  func stopLastSession() {
    self.session.stopSession()
    self.navigationController.dismiss(animated: true) {
      self.currentWallet = nil
      self.session = nil
      self.balanceCoordinator?.pause()
      self.balanceCoordinator = nil
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
