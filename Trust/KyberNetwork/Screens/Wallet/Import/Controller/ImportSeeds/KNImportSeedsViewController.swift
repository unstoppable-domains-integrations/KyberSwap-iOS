// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore

protocol KNImportSeedsViewControllerDelegate: class {
  func importSeedsViewControllerDidPressNext(sender: KNImportSeedsViewController, seeds: [String])
}

class KNImportSeedsViewController: KNBaseViewController {

  weak var delegate: KNImportSeedsViewControllerDelegate?
  fileprivate let numberWords: Int = 12

  @IBOutlet weak var recoverSeedsLabel: UILabel!
  @IBOutlet weak var descLabel: UILabel!
  @IBOutlet weak var seedsTextView: UITextView!

  @IBOutlet weak var nextButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.seedsTextView.rounded(radius: 4.0)
    self.nextButton.rounded(radius: 4.0)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.seedsTextView.text = ""
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    if let seeds = self.seedsTextView.text?.trimmed {
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
          seeds: words.map({ return String($0) })
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
