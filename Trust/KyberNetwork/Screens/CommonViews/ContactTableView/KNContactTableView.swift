// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNContactTableViewDelegate: class {
  func contactTableView(_ sender: KNContactTableView, didSelect contact: KNContact)
  func contactTableView(_ sender: KNContactTableView, didUpdate height: CGFloat)
}

class KNContactTableView: XibLoaderView {

  let kContactTableViewCellID: String = "kContactTableViewCellID"
  @IBOutlet weak var tableView: UITableView!

  fileprivate var contacts: [KNContact] = []

  weak var delegate: KNContactTableViewDelegate?

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(rawValue: kUpdateListContactNotificationKey),
      object: nil
    )
  }

  override func commonInit() {
    super.commonInit()
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: kContactTableViewCellID)
    self.tableView.rowHeight = 42
    self.tableView.delegate = self
    self.tableView.dataSource = self

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.shouldUpdateContacts(_:)),
      name: NSNotification.Name(rawValue: kUpdateListContactNotificationKey),
      object: nil
    )
  }

  func updateScrolling(isEnabled: Bool) {
    self.tableView.isScrollEnabled = isEnabled
    self.tableView.showsVerticalScrollIndicator = isEnabled
    self.tableView.showsHorizontalScrollIndicator = isEnabled
  }

  @objc func shouldUpdateContacts(_ sender: Notification?) {
    self.updateView(with: KNContactStorage.shared.contacts)
  }

  func updateView(with contacts: [KNContact]) {
    self.contacts = Array(contacts.prefix(3))
    self.tableView.reloadData()
    self.delegate?.contactTableView(self, didUpdate: self.tableView.rowHeight * CGFloat(self.contacts.count))
  }
}

extension KNContactTableView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.delegate?.contactTableView(self, didSelect: self.contacts[indexPath.row])
  }
}

extension KNContactTableView: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.contacts.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kContactTableViewCellID, for: indexPath)
    let contact: KNContact = self.contacts[indexPath.row]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "0c0033"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular),
    ]
    let addressAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: ""),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular),
    ]
    let attributedString: NSAttributedString = {
      let attributed: NSMutableAttributedString = NSMutableAttributedString()
      attributed.append(NSAttributedString(string: contact.name, attributes: nameAttributes))
      attributed.append(NSAttributedString(string: " - \(contact.address)", attributes: addressAttributes))
      return attributed
    }()
    cell.textLabel?.attributedText = attributedString
    return cell
  }
}
