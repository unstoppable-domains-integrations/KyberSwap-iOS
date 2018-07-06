// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNListContactViewEvent {
  case back
  case select(contact: KNContact)
}

protocol KNListContactViewControllerDelegate: class {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent)
}

class KNListContactViewController: KNBaseViewController {

  @IBOutlet weak var contactTableView: KNContactTableView!
  weak var delegate: KNListContactViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.contactTableView.delegate = self
    self.contactTableView.updateView(
      with: KNContactStorage.shared.contacts,
      isFull: true
    )
    self.contactTableView.updateScrolling(isEnabled: true)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.contactTableView.updateView(
      with: KNContactStorage.shared.contacts,
      isFull: true
    )
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.backButtonPressed(sender)
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.listContactViewController(self, run: .back)
  }

  @IBAction func addButtonPressed(_ sender: Any) {
    self.openNewContact(address: "")
  }

  fileprivate func openNewContact(address: String) {
    let viewModel = KNNewContactViewModel(address: address)
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController?.pushViewController(controller, animated: true)
  }
}

extension KNListContactViewController: KNContactTableViewDelegate {
  func contactTableView(_ tableView: UITableView, run event: KNContactTableViewEvent) {
    switch event {
    case .select(let contact):
      self.delegate?.listContactViewController(self, run: .select(contact: contact))
    case .delete(let contact):
      let alertController = UIAlertController(
        title: "Do you want to delete this contact?".toBeLocalised(),
        message: "",
        preferredStyle: .actionSheet
      )
      alertController.addAction(UIAlertAction(title: "Delete".toBeLocalised(), style: .destructive, handler: { _ in
        KNContactStorage.shared.delete(contacts: [contact])
      }))
      alertController.addAction(UIAlertAction(title: "Cancel".toBeLocalised(), style: .cancel, handler: nil))
      self.present(alertController, animated: true, completion: nil)
    case .edit(let contact):
      self.openNewContact(address: contact.address)
    default: break
    }
  }
}

extension KNListContactViewController: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    self.navigationController?.popViewController(animated: true)
  }
}
