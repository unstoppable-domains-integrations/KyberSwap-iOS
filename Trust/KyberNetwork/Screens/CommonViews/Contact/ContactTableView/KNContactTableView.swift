// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNContactTableViewEvent {
  case select(contact: KNContact)
  case delete(contact: KNContact)
  case update(height: CGFloat)
}

protocol KNContactTableViewDelegate: class {
  func contactTableView(_ tableView: UITableView, run event: KNContactTableViewEvent)
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
    self.tableView.rowHeight = 44
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
    self.contacts = Array(contacts.prefix(2))
    self.tableView.reloadData()
    self.delegate?.contactTableView(
      self.tableView,
      run: .update(height: self.tableView.rowHeight * CGFloat(self.contacts.count))
    )
  }
}

extension KNContactTableView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.delegate?.contactTableView(
      tableView,
      run: .select(contact: self.contacts[indexPath.row])
    )
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
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular),
    ]
    let address = "\(contact.address.prefix(12))...\(contact.address.suffix(10))"
    let attributedString: NSAttributedString = {
      let attributed: NSMutableAttributedString = NSMutableAttributedString()
      attributed.append(NSAttributedString(string: contact.name, attributes: nameAttributes))
      attributed.append(NSAttributedString(string: " - \(address)", attributes: addressAttributes))
      return attributed
    }()
    cell.textLabel?.attributedText = attributedString
    return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      self.delegate?.contactTableView(
        tableView,
        run: .delete(contact: self.contacts[indexPath.row])
      )
    }
  }
}
