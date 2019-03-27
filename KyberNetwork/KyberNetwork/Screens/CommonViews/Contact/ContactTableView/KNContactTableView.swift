// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNContactTableViewEvent {
  case select(contact: KNContact)
  case send(address: String)
  case delete(contact: KNContact)
  case edit(contact: KNContact)
  case update(height: CGFloat)
}

protocol KNContactTableViewDelegate: class {
  func contactTableView(_ tableView: UITableView, run event: KNContactTableViewEvent)
}

class KNContactTableView: XibLoaderView {

  let kContactTableViewCellID: String = "kContactTableViewCellID"
  @IBOutlet weak var tableView: UITableView!

  fileprivate var contacts: [KNContact] = []
  fileprivate var isFull: Bool = false

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
    let nib = UINib(nibName: KNContactTableViewCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: kContactTableViewCellID)
    self.tableView.rowHeight = KNContactTableViewCell.height
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

  func updateView(with contacts: [KNContact], isFull: Bool = false) {
    self.isFull = isFull
    self.contacts = isFull ? contacts : Array(contacts.prefix(2))
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
    let cell = tableView.dequeueReusableCell(withIdentifier: kContactTableViewCellID, for: indexPath) as! KNContactTableViewCell
    let contact: KNContact = self.contacts[indexPath.row]
    let viewModel = KNContactTableViewCellModel(
      contact: contact,
      index: isFull ? indexPath.row : 0
    )
    cell.update(with: viewModel)
    return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let send = UITableViewRowAction(style: .normal, title: NSLocalizedString("send", value: "Send", comment: "")) { (_, _) in
      self.delegate?.contactTableView(
        tableView,
        run: .send(address: self.contacts[indexPath.row].address)
      )
    }
    send.backgroundColor = UIColor.Kyber.shamrock
    let edit = UITableViewRowAction(style: .normal, title: NSLocalizedString("edit", value: "Edit", comment: "")) { (_, _) in
      self.delegate?.contactTableView(
        tableView,
        run: .edit(contact: self.contacts[indexPath.row])
      )
    }
    edit.backgroundColor = UIColor.Kyber.blueGreen
    let delete = UITableViewRowAction(style: .destructive, title: NSLocalizedString("delete", value: "Delete", comment: "")) { (_, _) in
      self.delegate?.contactTableView(
        tableView,
        run: .delete(contact: self.contacts[indexPath.row])
      )
    }
    delete.backgroundColor = UIColor.Kyber.strawberry
    return [delete, edit, send]
  }
}
