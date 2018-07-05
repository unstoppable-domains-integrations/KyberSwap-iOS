// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNImportJSONViewControllerDelegate: class {
  func importJSONViewControllerDidPressNext(sender: KNImportJSONViewController, json: String, password: String)
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

  @IBOutlet weak var importJSONTextLabel: UILabel!
  @IBOutlet weak var importJSONButton: UIButton!

  @IBOutlet weak var enterPasswordTextLabel: UILabel!
  @IBOutlet weak var enterPasswordTextField: UITextField!

  @IBOutlet weak var nextButton: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let attributedString: NSAttributedString = {
      return NSAttributedString(
        string: "Import from Files/Dropbox/etc".toBeLocalised(),
        attributes: self.buttonAttributes
      )
    }()
    self.importJSONButton.setAttributedTitle(attributedString, for: .normal)
    self.enterPasswordTextField.text = ""
  }

  fileprivate func setupUI() {
    self.importJSONTextLabel.text = "1. Import your JSON file".toBeLocalised()
    self.importJSONButton.rounded(radius: 4.0)
    let attributedString: NSAttributedString = {
      return NSAttributedString(
        string: "Import from Files/Dropbox/etc".toBeLocalised(),
        attributes: self.buttonAttributes
      )
    }()
    self.importJSONButton.setAttributedTitle(attributedString, for: .normal)

    let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.enterPasswordTextLabel.text = "2. Enter Password to Decrypt".toBeLocalised()
    self.enterPasswordTextField.rounded(radius: 4.0)
    self.enterPasswordTextField.leftViewMode = .always
    self.enterPasswordTextField.leftView = paddingView
    self.enterPasswordTextField.rightView = paddingView

    self.nextButton.rounded(radius: 4.0)
  }

  @IBAction func importJSONButtonPressed(_ sender: Any) {
    self.showDocumentPicker()
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    let password: String = self.enterPasswordTextField.text ?? ""
    if password.isEmpty || jsonData.isEmpty {
      self.showWarningTopBannerMessage(
        with: "Field Required".toBeLocalised(),
        message: "Please check your input data again.".toBeLocalised()
      )
    } else {
      self.delegate?.importJSONViewControllerDidPressNext(
        sender: self,
        json: self.jsonData,
        password: self.enterPasswordTextField.text ?? ""
      )
    }
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
