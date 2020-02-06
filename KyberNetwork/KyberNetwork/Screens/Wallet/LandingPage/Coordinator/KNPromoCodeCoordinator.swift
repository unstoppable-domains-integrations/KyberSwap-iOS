// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import Moya

protocol KNPromoCodeCoordinatorDelegate: class {
  func promoCodeCoordinatorDidCreate(_ wallet: Wallet, expiredDate: TimeInterval, destinationToken: String?, destAddress: String?, name: String?)
}

class KNPromoCodeCoordinator: Coordinator {

  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  weak var delegate: KNPromoCodeCoordinatorDelegate?

  lazy var rootViewController: KNPromoCodeViewController = {
    let controller = KNPromoCodeViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(navigationController: UINavigationController, keystore: Keystore) {
    self.navigationController = navigationController
    self.keystore = keystore
  }

  func start() {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_kybercode", customAttributes: ["action": "start"])
    self.rootViewController.resetUI()
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }
}

extension KNPromoCodeCoordinator: KNPromoCodeViewControllerDelegate {
  func promoCodeViewController(_ controller: KNPromoCodeViewController, promoCode: String, name: String) {}
  func promoCodeViewControllerDidClose() {
    self.stop()
  }

  fileprivate func didSuccessUnlockPromoCode(wallet: Wallet, name: String, expiredDate: TimeInterval, destinationToken: String, destAddress: String?) {
    let walletObject = KNWalletObject(
      address: wallet.address.description,
      name: name
    )
    KNWalletStorage.shared.add(wallets: [walletObject])
    let expiredString: String = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd MMM yyyy, HH:mm"
      return formatter.string(from: Date(timeIntervalSince1970: expiredDate))
    }()
    self.navigationController.showSuccessTopBannerMessage(
      with: NSLocalizedString("congratulations", value: "Congratulations!!!", comment: ""),
      message: String(format: NSLocalizedString("you.have.successfully.unlocked.your.promo.code", value: "You have successfully unlocked your Promo code. Please move all assets to your wallet by %@", comment: ""), expiredString),
      time: 5
    )
    self.delegate?.promoCodeCoordinatorDidCreate(
      wallet,
      expiredDate: expiredDate,
      destinationToken: destinationToken,
      destAddress: destAddress,
      name: name
    )
  }
}
