// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MessageUI

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
    self.noButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.noButton.frame.height / 2.0
    )
    self.yesButton.rounded(radius: self.yesButton.frame.height / 2.0)
    self.yesButton.applyGradient()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.backButton.isHidden = true

//    self.descriptionTextLabel.text = NSLocalizedString("transfer_consent_description_labeL", comment: "")
    self.descriptionTextLabel.attributedText = self.createAttributedStringTransferConsentText()
    self.scrollView.delegate = self

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapDescriptionLabel(_:)))
    self.descriptionTextLabel.addGestureRecognizer(tapGesture)
    self.descriptionTextLabel.isUserInteractionEnabled = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.yesButton.removeSublayer(at: 0)
    self.yesButton.applyGradient()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func yesButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_consent", customAttributes: ["action": "yes"])
    self.delegate?.transferConsentViewController(
      self,
      answer: true,
      isForceLogout: self.isForceLogout,
      authInfo: self.authInfo,
      userInfo: self.userInfo
    )
  }

  @IBAction func noButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_consent", customAttributes: ["action": "no"])
    let alert = UIAlertController(
      title: "Your profile will not be copied",
      message: "\nYou would have to create a new profile to use some services like Limit Order, Price Alerts, Notifications, etc. \n\nDo you want to continue?".toBeLocalised(),
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Go back".toBeLocalised(), style: .cancel, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_consent", customAttributes: ["action": "no_go_back"])
    }))
    alert.addAction(UIAlertAction(title: NSLocalizedString("continue", value: "Continue", comment: ""), style: .destructive, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_consent", customAttributes: ["action": "no_continue"])
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
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_consent", customAttributes: ["action": "dismiss_popup"])
    self.delegate?.transferConsentViewController(
      self,
      answer: nil,
      isForceLogout: self.isForceLogout,
      authInfo: self.authInfo,
      userInfo: self.userInfo
    )
  }

  @objc func didTapDescriptionLabel(_ sender: UITapGestureRecognizer) {
    if sender.didTapAttributedTextInLabel(label: self.descriptionTextLabel, inRange: NSRange(location: 921, length: 21)) {
      self.openMailSupport()
    } else if sender.didTapAttributedTextInLabel(label: self.descriptionTextLabel, inRange: NSRange(location: 965, length: 30)) {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_consent", customAttributes: ["action": "open_telegram"])
      self.openSafari(with: "https://t.me/kyberswapofficial")
    }
  }

  fileprivate func createAttributedStringTransferConsentText() -> NSMutableAttributedString {
    // swiftlint:disable line_length
    let attributedString = NSMutableAttributedString(string: "On Jan 24, 2020, KyberSwap.com and- related interfaces (the “Platform”) will no longer be operated by Kyber Network International Limited (“Kyber Network”) and will be operated by KYRD International Limited (“KYRD International”), a sister company incorporated and based in the British Virgin Islands (“BVI”). There are no other changes apart from the new operating entity of KyberSwap.com being changed to KYRD International.\n\nKYRD International is a company in BVI and as such, the country is not subject to an adequacy decision by the EU Commission on the processing of personal data. If you wish to continue using KyberSwap.com without providing personal data again, Kyber Network will transfer your current personal data to KYRD International upon your explicit consent. Please rest assured that KYRD International respects your privacy and is committed to protecting your personal data. For questions, please email support@kyberswap.com or reach out to us at https://t.me/kyberswapofficial \n\nKindly select:\n\n•  “Yes” if you wish to allow KyberSwap.com to copy your personal data to KYRD International; or\n\n•  “No” if you do not wish to copy your personal data to KYRD International. Note that if you click “No”, your personal data shall be erased in accordance with the retention periods specified in Kyber Network’s Privacy Policy. You will have to create a new profile on KyberSwap.com in order to, but not limited to, access Limit Orders, price alerts, personalized notifications and other benefits.", attributes: [
      .font: UIFont.Kyber.medium(with: 14),
      .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
    ])
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 102, length: 35))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 180, length: 26))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 278, length: 22))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 428, length: 18))
    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 239, green: 129, blue: 2), range: NSRange(location: 921, length: 21))
    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 239, green: 129, blue: 2), range: NSRange(location: 965, length: 30))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 998, length: 14))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 18), range: NSRange(location: 1014, length: 1))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 1018, length: 3))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 18), range: NSRange(location: 1112, length: 1))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 1116, length: 2))
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 3
    attributedString.addAttribute(
      .paragraphStyle,
      value: paragraphStyle,
      range: NSRange(location: 0, length: attributedString.length)
    )

    return attributedString
  }

  func openMailSupport() {
    if MFMailComposeViewController.canSendMail() {
      let emailVC = MFMailComposeViewController()
      emailVC.mailComposeDelegate = self
      emailVC.setToRecipients(["support@kyberswap.com"])
      self.present(emailVC, animated: true, completion: nil)
    } else {
      let message = NSLocalizedString(
        "please.send.your.request.to.support",
        value: "Please send your request to support@kyberswap.com",
        comment: ""
      )
      self.showWarningTopBannerMessage(with: "", message: message, time: 1.5)
    }
  }
}

extension KNTransferConsentViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height {
      self.backButton.isHidden = false // show back button, allow to back
    }
  }
}

extension KNTransferConsentViewController: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    if case .sent = result {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_consent", customAttributes: ["action": "support_email_sent"])
    }
    controller.dismiss(animated: true, completion: nil)
  }
}

extension UITapGestureRecognizer {
  func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
    guard let attrString = label.attributedText else { return false }

    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: .zero)
    let textStorage = NSTextStorage(attributedString: attrString)

    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)

    textContainer.lineFragmentPadding = 0
    textContainer.lineBreakMode = label.lineBreakMode
    textContainer.maximumNumberOfLines = label.numberOfLines
    let labelSize = label.bounds.size
    textContainer.size = labelSize

    let locationOfTouchInLabel = self.location(in: label)
    let textBoundingBox = layoutManager.usedRect(for: textContainer)
    let textContainerOffset = CGPoint(
      x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
      y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
    )
    let locationOfTouchInTextContainer = CGPoint(
      x: locationOfTouchInLabel.x - textContainerOffset.x,
      y: locationOfTouchInLabel.y - textContainerOffset.y
    )
    let indexOfCharacter = layoutManager.characterIndex(
      for: locationOfTouchInTextContainer,
      in: textContainer,
      fractionOfDistanceBetweenInsertionPoints: nil
    )
    return NSLocationInRange(indexOfCharacter, targetRange)
  }
}

