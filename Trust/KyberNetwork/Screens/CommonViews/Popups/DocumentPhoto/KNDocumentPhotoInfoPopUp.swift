// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNDocumentPhotoInfoPopUp: KNBaseViewController {

  @IBOutlet weak var documentPhotoTipsView: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()
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
