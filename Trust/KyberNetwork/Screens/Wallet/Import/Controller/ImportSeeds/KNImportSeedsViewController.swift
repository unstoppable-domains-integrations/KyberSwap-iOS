// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore

protocol KNImportSeedsViewControllerDelegate: class {
  func importSeedsViewControllerDidPressNext(sender: KNImportSeedsViewController, seeds: [String], name: String?)
}

class KNImportSeedsViewController: KNBaseViewController {

  weak var delegate: KNImportSeedsViewControllerDelegate?
  fileprivate let numberWords: Int = 12

  @IBOutlet weak var recoverSeedsLabel: UILabel!
  @IBOutlet weak var descLabel: UILabel!
  @IBOutlet weak var seedsTextField: UITextField!
  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var wordsCountLabel: UILabel!

  @IBOutlet weak var nextButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.seedsTextField.delegate = self
    self.nextButton.rounded(radius: self.nextButton.frame.height / 2.0)
    self.nextButton.setBackgroundColor(UIColor(red: 237, green: 238, blue: 242), forState: .disabled)
    self.nextButton.setBackgroundColor(UIColor.Kyber.shamrock, forState: .normal)
    self.resetUIs()
  }

  func resetUIs() {
    self.seedsTextField.text = ""
    self.wordsCountLabel.text = "Words Count: 0"
    self.walletNameTextField.text = ""
    self.updateNextButton()
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = {
      guard let seeds = self.seedsTextField.text?.trimmed else { return false }
      let words = seeds.components(separatedBy: " ").map({ $0.trimmed })
      return words.count == self.numberWords
    }()
    self.nextButton.isEnabled = enabled
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    if let seeds = self.seedsTextField.text?.trimmed {
      guard Mnemonic.isValid(seeds) else {
        self.parent?.showErrorTopBannerMessage(
          with: "Invalid Seeds".toBeLocalised(),
          message: "Please check your seeds again.".toBeLocalised()
        )
        return
      }
      let words = seeds.components(separatedBy: " ").map({ $0.trimmed })
      if words.count == self.numberWords {
        self.delegate?.importSeedsViewControllerDidPressNext(
          sender: self,
          seeds: words.map({ return String($0) }),
          name: self.walletNameTextField.text
        )
      } else {
        self.parent?.showErrorTopBannerMessage(
          with: "Invalid seeds".toBeLocalised(),
          message: "Seeds should have exactly 12 words".toBeLocalised())
      }
    } else {
      self.parent?.showErrorTopBannerMessage(
        with: "Field Required".toBeLocalised(),
        message: "Please check your input data".toBeLocalised())
    }
  }
}

extension KNImportSeedsViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.seedsTextField {
      self.wordsCountLabel.text = "Words Count: \(text.components(separatedBy: " ").map({ $0.trimmed }).count)"
      self.updateNextButton()
    }
    return false
  }
}
