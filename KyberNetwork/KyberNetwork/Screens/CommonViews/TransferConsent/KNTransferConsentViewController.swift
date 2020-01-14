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

  @IBOutlet weak var navTitleLabel: UILabel!
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
    self.navTitleLabel.text = "Transfer Consent".toBeLocalised()
    self.yesButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.yesButton.frame.height / 2.0
    )
    self.noButton.rounded(radius: self.noButton.frame.height / 2.0)
    self.noButton.applyGradient()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.backButton.isHidden = true

    self.descriptionTextLabel.text = NSLocalizedString("transfer_consent_description_labeL", comment: "")
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
    alert.addAction(UIAlertAction(title: "Go back".toBeLocalised(), style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: NSLocalizedString("continue", value: "Continue", comment: ""), style: .destructive, handler: { _ in
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
