// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNHoldingDocumentInfoPopUp: KNBaseViewController {

  @IBOutlet weak var holdingPhotoInfoView: UIView!
  @IBOutlet weak var detailsLabel: UILabel!
  @IBOutlet weak var photoHoldingDocLabel: UILabel!
  @IBOutlet weak var incorrectTextLabel: UILabel!
  @IBOutlet weak var correctTextLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.addGestureToDismiss()
  }

  fileprivate func addGestureToDismiss() {

    self.photoHoldingDocLabel.text = NSLocalizedString("photo.of.your.holding.document", value: "Photo of your holding Document", comment: "")
    //swiftlint:disable line_length
    self.detailsLabel.text = NSLocalizedString("photo.of.holding.document.tips", value: "Please hold the Passport/ID/Driving License in your hand next to your face.\n\nYour face and the Passport/ID must be clearly visible and any text, numbers or photos on the passport must be readable and not covered by your fingers.", comment: "")
    self.incorrectTextLabel.text = NSLocalizedString("incorrect", value: "Incorrect", comment: "")
    self.correctTextLabel.text = NSLocalizedString("correct", value: "Correct", comment: "")
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewDidTap(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  @objc func viewDidTap(_ sender: UITapGestureRecognizer) {
    let point = sender.location(in: self.view)
    if point.y < self.holdingPhotoInfoView.frame.minY {
      self.dismiss(animated: true, completion: nil)
    }
  }
}
