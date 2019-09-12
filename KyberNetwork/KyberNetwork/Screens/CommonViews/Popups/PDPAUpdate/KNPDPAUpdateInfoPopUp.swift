// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNPDPAUpdateInfoPopUp: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded(radius: 4.0)
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
}
