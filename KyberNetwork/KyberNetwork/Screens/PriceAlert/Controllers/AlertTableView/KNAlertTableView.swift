// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNAlertTableViewEvent {
  case select(alert: KNAlertObject)
  case delete(alert: KNAlertObject)
  case edit(alert: KNAlertObject)
  case update(height: CGFloat)
}

protocol KNAlertTableViewDelegate: class {
  func alertTableView(_ tableView: UITableView, run event: KNAlertTableViewEvent)
}

class KNAlertTableView: XibLoaderView {

  @IBOutlet weak var alertTableView: UITableView!
  let kAlertTableViewCellID: String = "kAlertTableViewCellID"

  fileprivate var alerts: [KNAlertObject] = []
  fileprivate var isFull: Bool = false

  override func commonInit() {
    super.commonInit()
    let nib = UINib(nibName: KNAlertTableViewCell.className, bundle: nil)
    self.alertTableView.register(nib, forCellReuseIdentifier: kAlertTableViewCellID)
    self.alertTableView.rowHeight = KNAlertTableViewCell.height
    self.alertTableView.delegate = self
    self.alertTableView.dataSource = self

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.updateListAlerts(_:)),
      name: NSNotification.Name(rawValue: kUpdateListAlertsNotificationKey),
      object: nil
    )
  }

  weak var delegate: KNAlertTableViewDelegate?

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(rawValue: kUpdateListAlertsNotificationKey),
      object: nil
    )
  }

  func updateScrolling(isEnabled: Bool) {
    self.alertTableView.isScrollEnabled = isEnabled
    self.alertTableView.showsVerticalScrollIndicator = isEnabled
    self.alertTableView.showsHorizontalScrollIndicator = isEnabled
  }

  @objc func updateListAlerts(_ sender: Notification?) {
    self.updateView(with: KNAlertStorage.shared.alerts, isFull: self.isFull)
  }

  func updateView(with alerts: [KNAlertObject], isFull: Bool = false) {
    self.isFull = isFull
    self.alerts = alerts.sorted(by: { (alert1, alert2) in
      // active always show first, sorted by created time
      // inactive always show last, sorted by updated time
      if alert1.state == .active && alert2.state == .active {
        return alert1.updatedDate > alert2.updatedDate
      }
      if alert1.state == .active { return true }
      if alert2.state == .active { return false }
      return alert1.updatedDate > alert2.updatedDate
    })
    if !isFull { self.alerts = Array(self.alerts.prefix(2)) }
    self.alertTableView.reloadData()
    self.delegate?.alertTableView(
      self.alertTableView,
      run: .update(height: self.alertTableView.rowHeight * CGFloat(self.alerts.count))
    )
  }
}

extension KNAlertTableView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.delegate?.alertTableView(
      tableView,
      run: .select(alert: self.alerts[indexPath.row])
    )
  }
}

extension KNAlertTableView: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.alerts.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kAlertTableViewCellID, for: indexPath) as! KNAlertTableViewCell
    let alert: KNAlertObject = self.alerts[indexPath.row]
    cell.updateCell(with: alert, index: indexPath.row)
    return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let edit = UITableViewRowAction(style: .normal, title: NSLocalizedString("edit", value: "Edit", comment: "")) { (_, _) in
      self.delegate?.alertTableView(
        tableView,
        run: .edit(alert: self.alerts[indexPath.row])
      )
    }
    edit.backgroundColor = UIColor.Kyber.blueGreen
    let delete = UITableViewRowAction(style: .destructive, title: NSLocalizedString("delete", value: "Delete", comment: "")) { (_, _) in
      self.delegate?.alertTableView(
        tableView,
        run: .delete(alert: self.alerts[indexPath.row])
      )
    }
    delete.backgroundColor = UIColor.Kyber.strawberry
    return [delete, edit]
  }
}
