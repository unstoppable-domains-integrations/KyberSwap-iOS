// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNDocumentPhotoInfoPopUp: KNBaseViewController {

  @IBOutlet weak var documentPhotoTipsView: UIView!
  @IBOutlet weak var photoOfYourDocLabel: UILabel!
  @IBOutlet weak var tipsHowDocumentShouldLookLabel: UILabel!
  @IBOutlet weak var mustShowAllCornersLabel: UILabel!
  @IBOutlet weak var mustNotBeCoveredLabel: UILabel!
  @IBOutlet weak var mustNotBeBlurryLabel: UILabel!
  @IBOutlet weak var rightLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.photoOfYourDocLabel.text = NSLocalizedString("photo.of.your.document", value: "Photo of your Document", comment: "")
    self.tipsHowDocumentShouldLookLabel.text = NSLocalizedString("tips.on.how.your.document.should.look", value: "Tips on How your Document should look", comment: "")
    self.mustShowAllCornersLabel.text = NSLocalizedString("must.show.all.four.corners.of.the.card", value: "Must show all 4 corners of the card", comment: "")
    self.mustNotBeCoveredLabel.text = NSLocalizedString("must.not.be.covered.in.anyway", value: "Must not be covered in anyway", comment: "")
    self.mustNotBeBlurryLabel.text = NSLocalizedString("must.not.be.blurry", value: "Must not be blurry", comment: "")
    self.rightLabel.text = NSLocalizedString("this.is.right", value: "This is right", comment: "")

    self.addGestureToDismiss()
  }

  fileprivate func addGestureToDismiss() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewDidTap(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  @objc func viewDidTap(_ sender: UITapGestureRecognizer) {
    let point = sender.location(in: self.view)
    if point.y < self.documentPhotoTipsView.frame.minY {
      self.dismiss(animated: true, completion: nil)
    }
  }
}
