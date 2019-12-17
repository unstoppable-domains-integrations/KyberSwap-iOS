// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNListNotificationViewModel {
  var notifications: [KNNotification] = []
}

class KNListNotificationViewController: KNBaseViewController {

  let kCellID = "kListNotificationTableViewCell"

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var markAllReadButton: UIButton!

  @IBOutlet weak var listNotiTableView: UITableView!

  @IBOutlet weak var emptyStateContainerView: UIView!
  @IBOutlet weak var noNotificationsTextLabel: UILabel!

  fileprivate let viewModel = KNListNotificationViewModel()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    let nib = UINib(nibName: KNNotificationTableViewCell.className, bundle: nil)
    self.listNotiTableView.register(nib, forCellReuseIdentifier: kCellID)
    self.listNotiTableView.delegate = self
    self.listNotiTableView.dataSource = self
    self.listNotiTableView.rowHeight = 60.0

    let name = Notification.Name(kUpdateListNotificationsKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.listNotificationsDidUpdate(_:)),
      name: name,
      object: nil
    )

    self.listNotificationsDidUpdate(nil)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let name = Notification.Name(kUpdateListNotificationsKey)
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.reloadListNotifications()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func reloadListNotifications() {
    self.displayLoading()
    KNNotificationCoordinator.shared.loadListNotifications { [weak self] (_, error) in
      guard let `self` = self else { return }
      self.hideLoading()
      if let err = error {
        self.showSuccessTopBannerMessage(
          with: NSLocalizedString("error", comment: ""),
          message: err,
          time: 2.0
        )
      }
    }
  }

  @objc func listNotificationsDidUpdate(_ sender: Any?) {
    self.viewModel.notifications = KNNotificationStorage.shared.notifications.map({ return $0.clone() }).sorted(by: { return $0.updatedDate > $1.updatedDate })
    self.emptyStateContainerView.isHidden = !self.viewModel.notifications.isEmpty
    self.listNotiTableView.isHidden = self.viewModel.notifications.isEmpty
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func markAllButtonPressed(_ sender: Any) {
    let ids = KNNotificationStorage.shared.notifications.map({ return $0.id })
    self.displayLoading()
    KNNotificationCoordinator.shared.markAsRead(ids: ids) { [weak self] error in
      guard let `self` = self else { return }
      self.hideLoading()
      if let err = error {
        self.showSuccessTopBannerMessage(
          with: NSLocalizedString("error", comment: ""),
          message: err,
          time: 2.0
        )
      }
    }
  }
}

extension KNListNotificationViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let noti = self.viewModel.notifications[indexPath.row]
    if !noti.read {
      KNNotificationCoordinator.shared.markAsRead(ids: [noti.id]) { _ in }
    }
    let alert = UIAlertController(title: noti.title, message: noti.content, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    if !noti.link.isEmpty, let url = URL(string: noti.link) {
      alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { _ in
        self.openSafari(with: url)
      }))
    }
    self.present(alert, animated: true, completion: nil)
  }
}

extension KNListNotificationViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.notifications.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath) as! KNNotificationTableViewCell
    let noti = self.viewModel.notifications[indexPath.row]
    cell.updateCell(with: noti, index: indexPath.row)
    return cell
  }
}
