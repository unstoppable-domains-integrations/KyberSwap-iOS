// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KYCProfileVerificationStatusViewController: KNBaseViewController {

  @IBOutlet weak var statusLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.statusLabel.text = "\(NSLocalizedString("your.profile.verification.status", value: "Your Profile Verification Status", comment: "")): \(NSLocalizedString("pending", value: "Pending", comment: ""))"
  }

}
