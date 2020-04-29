// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNSaveContactViewEvent {
  case cancel
  case save(address: String, name: String)
}

protocol KNSaveContactViewControllerDelegate: class {
  func saveContactViewController(_ controller: KNSaveContactViewController, run event: KNSaveContactViewEvent)
}

class KNSaveContactViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var contactNameTextField: UITextField!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var saveButton: UIButton!

  fileprivate let address: String
  weak var delegate: KNSaveContactViewControllerDelegate?

  init(address: String) {
    self.address = address
    super.init(nibName: KNSaveContactViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    self.contactNameTextField.layer.borderColor = UIColor.Kyber.darkerGrey.cgColor
    self.containerView.rounded(radius: 4.0)
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.delegate?.saveContactViewController(self, run: .cancel)
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    guard let text = self.contactNameTextField.text else { return }
    self.delegate?.saveContactViewController(self, run: .save(address: self.address, name: text))
  }
}
