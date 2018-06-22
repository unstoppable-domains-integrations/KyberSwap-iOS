// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import QRCodeReaderViewController

enum KNNewContactViewEvent {
  case dismiss
}

protocol KNNewContactViewControllerDelegate: class {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent)
}

class KNNewContactViewModel {

  fileprivate(set) var contact: KNContact
  fileprivate(set) var isEditing: Bool

  init(
    address: String
  ) {
    if let contact = KNContactStorage.shared.get(forPrimaryKey: address.lowercased()) {
      self.contact = contact
      self.isEditing = true
    } else {
      self.contact = KNContact(address: address.lowercased(), name: "")
      self.isEditing = false
    }
  }

  var title: String {
    return isEditing ? "Edit Contact".toBeLocalised() : "Add Contact".toBeLocalised()
  }

  func updateViewModel(address: String) {
    if let contact = KNContactStorage.shared.get(forPrimaryKey: address.lowercased()) {
      self.contact = contact
      self.isEditing = true
    } else {
      self.contact = KNContact(address: address.lowercased(), name: "")
      self.isEditing = false
    }
  }
}

class KNNewContactViewController: KNBaseViewController {

  weak var delegate: KNNewContactViewControllerDelegate?
  fileprivate var viewModel: KNNewContactViewModel

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var saveButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var addressTextField: UITextField!

  init(viewModel: KNNewContactViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNNewContactViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.saveButton.setTitle("Save".toBeLocalised(), for: .normal)
    self.deleteButton.setTitle("Delete".toBeLocalised(), for: .normal)
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.titleLabel.text = self.viewModel.title
    self.nameTextField.text = self.viewModel.contact.name
    self.addressTextField.text = self.viewModel.contact.address
    self.deleteButton.isHidden = !self.viewModel.isEditing
  }

  func updateView(viewModel: KNNewContactViewModel) {
    self.viewModel = viewModel
    self.updateUI()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.newContactViewController(self, run: .dismiss)
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    guard let name = self.nameTextField.text else {
      self.showWarningTopBannerMessage(with: "", message: "Contact should have a name".toBeLocalised())
      return
    }
    guard let address = self.addressTextField.text, Address(string: address) != nil else {
      self.showWarningTopBannerMessage(with: "Invalid address".toBeLocalised(), message: "Please enter a valid address".toBeLocalised())
      return
    }
    let contact = KNContact(address: address.lowercased(), name: name)
    KNContactStorage.shared.update(contacts: [contact])
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
    self.delegate?.newContactViewController(self, run: .dismiss)
  }

  @IBAction func deleteButtonPressed(_ sender: Any) {
    let alertController = UIAlertController(title: "Delete?", message: "Do you want to delete this contact?", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
      KNContactStorage.shared.delete(contacts: [self.viewModel.contact])
      KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
      self.delegate?.newContactViewController(self, run: .dismiss)
    }))
    self.present(alertController, animated: true, completion: nil)
  }

  @IBAction func qrcodeButtonPressed(_ sender: Any) {
    let qrcodeVC = QRCodeReaderViewController()
    qrcodeVC.delegate = self
    self.present(qrcodeVC, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanAction(_ sender: Any) {
    self.delegate?.newContactViewController(self, run: .dismiss)
  }
}

extension KNNewContactViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.addressTextField.text = result
    }
  }
}
