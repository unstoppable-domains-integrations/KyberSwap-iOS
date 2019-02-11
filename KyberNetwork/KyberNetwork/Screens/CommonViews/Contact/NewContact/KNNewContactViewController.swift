// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import QRCodeReaderViewController
import Crashlytics

enum KNNewContactViewEvent {
  case dismiss
  case send(address: String)
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
    if let contact = KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == address.lowercased() }) {
      self.contact = contact
      self.isEditing = true
    } else {
      self.contact = KNContact(address: address.lowercased(), name: "")
      self.isEditing = false
    }
  }

  var title: String {
    return isEditing ? NSLocalizedString("edit.contact", value: "Edit Contact", comment: "") : NSLocalizedString("add.contact", value: "Add Contact", comment: "")
  }

  func updateViewModel(address: String) {
    if let contact = KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == address.lowercased() }) {
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

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var saveButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!
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

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.saveButton.setTitle(NSLocalizedString("save", value: "Save", comment: ""), for: .normal)
    self.deleteButton.setTitle(NSLocalizedString("delete.contact", value: "Delete Contact", comment: ""), for: .normal)
    self.sendButton.setTitle(NSLocalizedString("send", value: "Send", comment: ""), for: .normal)
    self.sendButton.setTitleColor(UIColor.Kyber.enygold, for: .normal)
    self.addressTextField.delegate = self
    self.nameTextField.placeholder = NSLocalizedString("name", value: "Name", comment: "")
    self.addressTextField.placeholder = NSLocalizedString("address", value: "Address", comment: "")
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.titleLabel.text = self.viewModel.title
    self.nameTextField.text = self.viewModel.contact.name
    self.addressTextField.text = self.viewModel.contact.address
    self.deleteButton.isHidden = !self.viewModel.isEditing
  }

  fileprivate func addressTextFieldDidChange() {
    let text = self.addressTextField.text ?? ""
    self.viewModel.updateViewModel(address: text)

    if self.nameTextField.text == nil || self.nameTextField.text?.isEmpty == true {
      self.nameTextField.text = self.viewModel.contact.name
    }
    self.titleLabel.text = self.viewModel.title
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
    KNCrashlyticsUtil.logCustomEvent(withName: "new_contact", customAttributes: ["type": "save_button"])
    guard let name = self.nameTextField.text, !name.isEmpty else {
      self.showWarningTopBannerMessage(with: "", message: NSLocalizedString("contact.should.have.a.name", value: "Contact should have a name", comment: ""))
      return
    }
    guard let address = self.addressTextField.text, Address(string: address) != nil else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.address", value: "Invalid Address", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.address.to.continue", value: "Please enter a valid address to continue", comment: "")
      )
      return
    }
    let contact = KNContact(address: address.lowercased(), name: name)
    KNContactStorage.shared.update(contacts: [contact])
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
    self.delegate?.newContactViewController(self, run: .dismiss)
  }

  @IBAction func deleteButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_contact", customAttributes: ["type": "delete_button"])
    let alertController = UIAlertController(
      title: "",
      message: NSLocalizedString("do.you.want.to.delete.this.contact", value: "Do you want to delete this contact?", comment: ""),
      preferredStyle: .actionSheet
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("delete", value: "Delete", comment: ""), style: .destructive, handler: { _ in
      KNContactStorage.shared.delete(contacts: [self.viewModel.contact])
      KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
      self.delegate?.newContactViewController(self, run: .dismiss)
    }))
    self.present(alertController, animated: true, completion: nil)
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_contact", customAttributes: ["type": "send_button"])
    guard let address = Address(string: self.addressTextField.text ?? "") else {
      self.showErrorTopBannerMessage(
        with: NSLocalizedString("invalid.address", value: "Invalid Address", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.address.to.continue", value: "Please enter a valid address to continue", comment: ""),
        time: 2.0
      )
      return
    }
    self.delegate?.newContactViewController(self, run: .send(address: address.description))
  }

  @IBAction func qrcodeButtonPressed(_ sender: Any) {
    let qrcodeVC = QRCodeReaderViewController()
    qrcodeVC.delegate = self
    self.present(qrcodeVC, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.newContactViewController(self, run: .dismiss)
    }
  }
}

extension KNNewContactViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.addressTextField {
      self.addressTextFieldDidChange()
    }
    return false
  }
}

extension KNNewContactViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.addressTextField.text = result
      self.addressTextFieldDidChange()
    }
  }
}
