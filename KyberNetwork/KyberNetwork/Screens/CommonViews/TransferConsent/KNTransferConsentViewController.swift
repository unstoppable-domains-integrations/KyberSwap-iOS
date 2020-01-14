// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNTransferConsentViewControllerDelegate: class {
  // yes/no/undecide
  func transferConsentViewController(
    _ controller: KNTransferConsentViewController,
    answer: Bool?,
    isForceLogout: Bool,
    authInfo: JSONDictionary,
    userInfo: JSONDictionary
  )
}

class KNTransferConsentViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var yesButton: UIButton!
  @IBOutlet weak var noButton: UIButton!
  @IBOutlet weak var descriptionTextLabel: UILabel!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var backButton: UIButton!

  let isForceLogout: Bool
  let authInfo: JSONDictionary
  let userInfo: JSONDictionary

  weak var delegate: KNTransferConsentViewControllerDelegate?

  init(isForceLogout: Bool, authInfo: JSONDictionary, userInfo: JSONDictionary) {
    self.isForceLogout = isForceLogout
    self.authInfo = authInfo
    self.userInfo = userInfo
    super.init(nibName: KNTransferConsentViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.yesButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.yesButton.frame.height / 2.0
    )
    self.noButton.rounded(radius: self.noButton.frame.height / 2.0)
    self.noButton.applyGradient()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.backButton.isHidden = true

    //swiftlint:disable line_length
    self.descriptionTextLabel.text = "Please note that in view of business and strategic considerations, Kyber Network International Limited (“Kyber Network”) no longer operates kyberswap.com.\n\nKYRD International Limited (“KYRD International”) now operates kyberswap.com. We assure you that no other change is in place other than that KYRD International is now the entity operating kyberswap.com instead of Kyber Network.\n\nIf you wish, to continue using kyberswap.com without the need of providing your personal data again, Kyber Network can transfer your personal data to KYRD International upon your explicit consent.\n\nPlease do note that KYRD International is a company in British Virgin Islands (\"BVI\") and as such, the country is not subject to an adequacy decision by the EU Commission on the processing of personal data nor are there the appropriate safeguards for data protection purposes that are present in EU jurisdictions.\n\nKindly click:\n\"Yes\" if you wish that Kyber Network transfers your personal data to KYRD International; or\n\"No\" if you do not wish that Kyber Network transfers your personal data to KYRD International Do note that if you click “No”, your personal shall be erased in accordance with the retention periods specified in Kyber Network’s Privacy Policy."
    self.scrollView.delegate = self
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.noButton.removeSublayer(at: 0)
    self.noButton.applyGradient()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func yesButtonPressed(_ sender: Any) {
    self.delegate?.transferConsentViewController(
      self,
      answer: true,
      isForceLogout: self.isForceLogout,
      authInfo: self.authInfo,
      userInfo: self.userInfo
    )
  }

  @IBAction func noButtonPressed(_ sender: Any) {
    let alert = UIAlertController(
      title: "Your profile will not be copied",
      message: "\nYou would have to create a new profile to use some services like Limit Order, Price Alerts, Notifications, etc. \n\nDo you want to continue?".toBeLocalised(),
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Go back", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "Continue", style: .destructive, handler: { _ in
      self.delegate?.transferConsentViewController(
        self,
        answer: false,
        isForceLogout: self.isForceLogout,
        authInfo: self.authInfo,
        userInfo: self.userInfo
      )
    }))
    self.present(alert, animated: true, completion: nil)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.transferConsentViewController(
      self,
      answer: nil,
      isForceLogout: self.isForceLogout,
      authInfo: self.authInfo,
      userInfo: self.userInfo
    )
  }
}

extension KNTransferConsentViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height {
      self.backButton.isHidden = false // show back button, allow to back
    }
  }
}
