// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNListContactViewEvent {
  case back
  case select(contact: KNContact)
  case send(address: String)
}

protocol KNListContactViewControllerDelegate: class {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent)
}

class KNListContactViewController: KNBaseViewController {

  @IBOutlet weak var contactTableView: KNContactTableView!
  @IBOutlet weak var emptyStateView: UIView!
  @IBOutlet weak var contactEmptyLabel: UILabel!
  @IBOutlet weak var addContactButton: UIButton!

  weak var delegate: KNListContactViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    let contacts = KNContactStorage.shared.contacts
    self.contactTableView.delegate = self
    self.contactTableView.updateView(
      with: contacts,
      isFull: true
    )
    self.contactTableView.updateScrolling(isEnabled: true)

    self.contactTableView.isHidden = contacts.isEmpty
    self.emptyStateView.isHidden = !contacts.isEmpty
    self.contactEmptyLabel.text = "Your contact is empty".toBeLocalised()
    self.addContactButton.rounded(radius: self.addContactButton.frame.height / 2.0)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let contacts = KNContactStorage.shared.contacts
    self.contactTableView.updateView(
      with: contacts,
      isFull: true
    )
    self.emptyStateView.isHidden = !contacts.isEmpty
    self.contactTableView.isHidden = contacts.isEmpty
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
    case .send(let address):
      self.delegate?.listContactViewController(self, run: .send(address: address))
    default:
      let contacts = KNContactStorage.shared.contacts
      self.emptyStateView.isHidden = !contacts.isEmpty
      self.contactTableView.isHidden = contacts.isEmpty
    }
  }
}

extension KNListContactViewController: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    self.navigationController?.popViewController(animated: true, completion: {
      if case .send(let address) = event {
        self.delegate?.listContactViewController(self, run: .send(address: address))
      }
    })
  }
}
