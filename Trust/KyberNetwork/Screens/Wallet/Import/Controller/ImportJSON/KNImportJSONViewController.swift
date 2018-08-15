// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNImportJSONViewControllerDelegate: class {
  func importJSONViewControllerDidPressNext(sender: KNImportJSONViewController, json: String, password: String, name: String?)
}

class KNImportJSONViewController: KNBaseViewController {

  weak var delegate: KNImportJSONViewControllerDelegate?
  fileprivate var jsonData: String = ""

  lazy var buttonAttributes: [NSAttributedStringKey: Any] = {
    return [
      NSAttributedStringKey.foregroundColor: UIColor.black,
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16),
    ]
  }()

  @IBOutlet weak var nameWalletTextField: UITextField!
  @IBOutlet weak var importJSONButton: UIButton!
  @IBOutlet weak var enterPasswordTextField: UITextField!
  @IBOutlet weak var secureTextButton: UIButton!

  @IBOutlet weak var nextButton: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  func resetUIs() {
    let attributedString: NSAttributedString = {
      return NSAttributedString(
        string: "Import your JSON file".toBeLocalised(),
        attributes: self.buttonAttributes
      )
    }()
    self.jsonData = ""
    self.importJSONButton.setAttributedTitle(attributedString, for: .normal)
    self.nameWalletTextField.text = ""
    self.enterPasswordTextField.text = ""
    self.secureTextButton.setImage(UIImage(named: "hide_secure_text"), for: .normal)
    self.enterPasswordTextField.isSecureTextEntry = true

    self.updateNextButton()
  }

  fileprivate func setupUI() {
    self.importJSONButton.rounded(
      color: UIColor.Kyber.border,
      width: 1,
      radius: self.importJSONButton.frame.height / 2.0
    )
    self.enterPasswordTextField.delegate = self

    self.nextButton.rounded(radius: self.nextButton.frame.height / 2.0)
    self.nextButton.setBackgroundColor(UIColor(red: 237, green: 238, blue: 242), forState: .disabled)
    self.nextButton.setBackgroundColor(UIColor.Kyber.shamrock, forState: .normal)
    self.resetUIs()
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = {
      guard let password = self.enterPasswordTextField.text else { return false }
      return !password.isEmpty && !self.jsonData.isEmpty
    }()
    self.nextButton.isEnabled = enabled
  }

  @IBAction func importJSONButtonPressed(_ sender: Any) {
    self.showDocumentPicker()
  }

  @IBAction func secureTextButtonPressed(_ sender: Any) {
    self.enterPasswordTextField.isSecureTextEntry = !self.enterPasswordTextField.isSecureTextEntry
    self.secureTextButton.setImage(UIImage(named: self.enterPasswordTextField.isSecureTextEntry ? "hide_secure_text" : "show_secure_text"), for: .normal)
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    let password: String = self.enterPasswordTextField.text ?? ""
    self.delegate?.importJSONViewControllerDidPressNext(
      sender: self,
      json: self.jsonData,
      password: password,
      name: self.nameWalletTextField.text
    )
  }
}

// MARK: Update from coordinator
extension KNImportJSONViewController {
  fileprivate func showDocumentPicker() {
    let controller: TrustDocumentPickerViewController = {
      let types = ["public.text", "public.content", "public.item", "public.data"]
      let vc = TrustDocumentPickerViewController(
        documentTypes: types,
        in: .import
      )
      vc.delegate = self
      vc.modalPresentationStyle = .formSheet
      return vc
    }()
    self.present(controller, animated: true, completion: nil)
  }
}

extension KNImportJSONViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    if controller.documentPickerMode == UIDocumentPickerMode.import {
      if let text = try? String(contentsOfFile: url.path) {
        self.jsonData = text
        let name = url.lastPathComponent
        UIView.transition(
          with: self.importJSONButton,
          duration: 0.32,
          options: .transitionFlipFromTop,
          animations: {
            let attributedString: NSAttributedString = {
              return NSAttributedString(
                string: name.toBeLocalised(),
                attributes: self.buttonAttributes
              )
            }()
            self.importJSONButton.setAttributedTitle(attributedString, for: .normal)
            self.updateNextButton()
          }, completion: nil
        )
      } else {
        self.parent?.showErrorTopBannerMessage(
          with: "",
          message: "Can not get data from your file.".toBeLocalised()
        )
      }
    }
  }
}

extension KNImportJSONViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.enterPasswordTextField {
      self.updateNextButton()
    }
    return false
  }
}
