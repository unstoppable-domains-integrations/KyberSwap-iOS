// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNExchangeTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession
  let balanceCoordinator: KNBalanceCoordinator

  weak var delegate: KNSessionDelegate?

  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNExchangeTokenViewController = {
    let controller = KNExchangeTokenViewController(delegate: self)
    controller.applyBaseGradientBackground()
    return controller
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession,
    balanceCoordinator: KNBalanceCoordinator
    ) {
    self.navigationController = navigationController
    self.session = session
    self.balanceCoordinator = balanceCoordinator
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.addObserveNotifications()
  }

  func stop() {
    self.removeObserveNotifications()
  }

  fileprivate func addObserveNotifications() {
    let name = Notification.Name(KNBalanceCoordinator.KNBalanceNotificationKeys.ethBalanceDidUpdate.rawValue)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.ethBalanceDidUpdateNotification(_:)),
      name: name,
      object: nil
    )
    let tokenBalanceName = Notification.Name(KNBalanceCoordinator.KNBalanceNotificationKeys.otherTokensBalanceDidUpdate.rawValue)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenBalancesDidUpdateNotification(_:)),
      name: tokenBalanceName,
      object: nil
    )
    let rateUSDName = Notification.Name(KNRateCoordinator.KNRateNotificationKeys.exchangeRateUSDDidUpdateKey.rawValue)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.usdRateDidUpdateNotification(_:)), name: rateUSDName, object: nil)
  }

  fileprivate func removeObserveNotifications() {
    let name = Notification.Name(KNBalanceCoordinator.KNBalanceNotificationKeys.ethBalanceDidUpdate.rawValue)
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
    let tokenBalanceName = Notification.Name(KNBalanceCoordinator.KNBalanceNotificationKeys.otherTokensBalanceDidUpdate.rawValue)
    NotificationCenter.default.removeObserver(self, name: tokenBalanceName, object: nil)
    let rateUSDName = Notification.Name(KNRateCoordinator.KNRateNotificationKeys.exchangeRateUSDDidUpdateKey.rawValue)
    NotificationCenter.default.removeObserver(self, name: rateUSDName, object: nil)
  }

  @objc func tokenBalancesDidUpdateNotification(_ sender: Any) {
    self.rootViewController.updateBalance(usd: self.balanceCoordinator.totalBalanceInUSD, eth: self.balanceCoordinator.totalBalanceInETH)
  }

  @objc func ethBalanceDidUpdateNotification(_ sender: Any) {
    self.rootViewController.updateBalance(usd: self.balanceCoordinator.totalBalanceInUSD, eth: self.balanceCoordinator.totalBalanceInETH)
  }

  @objc func usdRateDidUpdateNotification(_ sender: Any) {
    self.rootViewController.updateBalance(usd: self.balanceCoordinator.totalBalanceInUSD, eth: self.balanceCoordinator.totalBalanceInETH)
  }
}

extension KNExchangeTokenCoordinator: KNExchangeTokenViewControllerDelegate {
}
