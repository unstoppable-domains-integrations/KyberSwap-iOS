// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNManageAlertCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KNManageAlertsViewController = {
    let controller = KNManageAlertsViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var newAlertController: KNNewAlertViewController?

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }
}

extension KNManageAlertCoordinator: KNManageAlertsViewControllerDelegate {
  func manageAlertsViewControllerShouldBack() {
    self.stop()
  }

  func manageAlertsViewControllerAddNewAlert() {
    if KNAlertStorage.shared.isMaximumAlertsReached {
      let alertController = UIAlertController(
        title: "Cap reached".toBeLocalised(),
        message: "You can only have maximum of 10 alerts".toBeLocalised(),
        preferredStyle: .alert
      )
      alertController.addAction(UIAlertAction(title: "OK".toBeLocalised(), style: .cancel, handler: nil))
      self.navigationController.present(alertController, animated: true, completion: nil)
    } else {
      self.newAlertController = KNNewAlertViewController()
      self.newAlertController?.loadViewIfNeeded()
      self.navigationController.pushViewController(self.newAlertController!, animated: true)
    }
  }

  func manageAlertsViewControllerRunEvent(_ event: KNAlertTableViewEvent) {
    switch event {
    case .delete(let alert):
      let alertController = UIAlertController(title: "Delete?".toBeLocalised(), message: "Do you want to delete this alert?".toBeLocalised(), preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
      alertController.addAction(UIAlertAction(title: "Delete".toBeLocalised(), style: .destructive, handler: { _ in
        self.deleteAnAlert(alert)
      }))
      self.navigationController.present(alertController, animated: true, completion: nil)
    case .edit(let alert):
      self.openEditAlert(alert)
    case .select(let alert):
      self.openEditAlert(alert)
    default: break
    }
  }

  fileprivate func deleteAnAlert(_ alert: KNAlertObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_alert", customAttributes: ["type": "delete_alert"])
    self.navigationController.displayLoading()
    KNPriceAlertCoordinator.shared.removeAnAlert(alert) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success:
        self.navigationController.showSuccessTopBannerMessage(
          with: "",
          message: "Alert deleted!".toBeLocalised(),
          time: 1.0
        )
      case .failure(let error):
        KNCrashlyticsUtil.logCustomEvent(
          withName: "manage_alert",
          customAttributes: ["type": "delete_alert_failed", "error": error.prettyError]
        )
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.prettyError,
          time: 1.5
        )
      }
    }
  }

  fileprivate func openEditAlert(_ alert: KNAlertObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_alert", customAttributes: ["type": "open_edit_alert"])
    self.newAlertController = KNNewAlertViewController()
    self.newAlertController?.loadViewIfNeeded()
    self.navigationController.pushViewController(self.newAlertController!, animated: true) {
      self.newAlertController?.updateEditAlert(alert)
    }
  }
}
