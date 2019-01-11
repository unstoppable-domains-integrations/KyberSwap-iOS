// Copyright SIX DAY LLC. All rights reserved.

//swiftlint:disable file_length
import UIKit
import Photos
import MobileCoreServices
import AVFoundation

enum KYCIdentityInfoViewEvent {
  case next(docType: String, docNum: String, issueDate: String, expiryDate: String, docFrontImage: UIImage, docBackImage: UIImage?, docHoldingImage: UIImage)
}

protocol KYCIdentityInfoViewControllerDelegate: class {
  func identityInfoViewController(_ controller: KYCIdentityInfoViewController, run event: KYCIdentityInfoViewEvent)
}

class KYCIdentityInfoViewModel {

  fileprivate(set) var documentType: String = ""
  fileprivate(set) var hasIssueDate: Bool = true
  fileprivate(set) var hasExpiryDate: Bool = true

  func updateDocumentType(_ type: String) { self.documentType = type }
  func updateHasIssueDate(has: Bool) { self.hasIssueDate = has }
  func updateHasExpiryDate(has: Bool) { self.hasExpiryDate = has }

  var dontHaveIssueDateImage: UIImage? {
    if self.hasIssueDate { return nil }
    return UIImage(named: "check_box_icon" )
  }

  var dontHaveIssueDateButtonBorder: UIColor {
    if self.hasIssueDate { return UIColor.Kyber.border }
    return UIColor.clear
  }

  var dontHaveExpiryDateImage: UIImage? {
    if self.hasExpiryDate { return nil }
    return UIImage(named: "check_box_icon" )
  }

  var dontHaveExpiryDateButtonBorder: UIColor {
    if self.hasExpiryDate { return UIColor.Kyber.border }
    return UIColor.clear
  }
}

class KYCIdentityInfoViewController: KNBaseViewController {

  @IBOutlet weak var documentTypeTextLabel: UILabel!
  @IBOutlet weak var idButton: UIButton!
  @IBOutlet weak var idTextLabel: UILabel!
  @IBOutlet weak var passportButton: UIButton!
  @IBOutlet weak var identityCardTextLabel: UILabel!
  @IBOutlet weak var passportTextLabel: UILabel!
  @IBOutlet weak var documentNumberTextField: UITextField!

  @IBOutlet weak var issueDateTextField: UITextField!
  @IBOutlet weak var dontHaveIssueDateButton: UIButton!
  @IBOutlet weak var dontHaveIssueDateTextLabel: UILabel!
  @IBOutlet weak var expiryDateTextField: UITextField!
  @IBOutlet weak var dontHaveExpiryDateButton: UIButton!
  @IBOutlet weak var dontHaveExpiryDateTextLabel: UILabel!

  fileprivate var documentFrontImage: UIImage?
  @IBOutlet weak var photoOfYourDocumentTextLabel: UILabel!
  @IBOutlet weak var browseDocumentButton: UIButton!
  @IBOutlet weak var documentImageContainerView: UIView!
  @IBOutlet weak var documentImageView: UIImageView!
  @IBOutlet weak var heightConstraintForDocumentPhotoView: NSLayoutConstraint!

  @IBOutlet weak var photoBackContainerView: UIView!
  fileprivate var documentBackImage: UIImage?
  @IBOutlet weak var photoOfYourDocumentBackTextLabel: UILabel!
  @IBOutlet weak var browserDocumentBackButton: UIButton!
  @IBOutlet weak var documentImageBackContainerView: UIView!
  @IBOutlet weak var documentBackImageView: UIImageView!
  @IBOutlet weak var heightConstraintForDocumentPhotoBackView: NSLayoutConstraint!
  @IBOutlet weak var photoBackInfoButton: UIButton!

  @IBOutlet weak var topPaddingForPhotoHoldingDocumentConstraint: NSLayoutConstraint!
  fileprivate var holdingDocumentImage: UIImage?
  @IBOutlet weak var photoHoldingDocumentTextLabel: UILabel!
  @IBOutlet weak var browseHoldingDocumentPhotoButton: UIButton!
  @IBOutlet weak var holdingDocumentImageContainerView: UIView!
  @IBOutlet weak var holdingDocumentImageView: UIImageView!
  @IBOutlet weak var heightConstraintForHoldingDocumentPhotoView: NSLayoutConstraint!

  @IBOutlet weak var nextButton: UIButton!

  weak var delegate: KYCIdentityInfoViewControllerDelegate?
  fileprivate let viewModel: KYCIdentityInfoViewModel

  fileprivate var pickingDocumentType: Int = 0 // 0: front, 1: back, 2: selfie
  fileprivate var imagePicker: UIImagePickerController = UIImagePickerController()

  fileprivate var isDatePickerIssueDate: Bool = true

  lazy var issueDatePicker: UIDatePicker = {
    let frame = CGRect(
      x: 0,
      y: self.view.frame.height - 200.0,
      width: self.view.frame.width,
      height: 200.0
    )
    let picker = UIDatePicker(frame: frame)
    picker.datePickerMode = .date
    picker.minimumDate = Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    picker.maximumDate = Date()
    picker.addTarget(self, action: #selector(self.issueDatePickerDidChange(_:)), for: .valueChanged)
    picker.date = Date()
    return picker
  }()

  lazy var expiryDatePicker: UIDatePicker = {
    let frame = CGRect(
      x: 0,
      y: self.view.frame.height - 200.0,
      width: self.view.frame.width,
      height: 200.0
    )
    let picker = UIDatePicker(frame: frame)
    picker.datePickerMode = .date
    picker.minimumDate = Date()
    picker.maximumDate = Date().addingTimeInterval(200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    picker.addTarget(self, action: #selector(self.expiryDatePickerDidChange(_:)), for: .valueChanged)
    picker.date = Date()
    return picker
  }()

  init(viewModel: KYCIdentityInfoViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KYCIdentityInfoViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.nextButton.removeSublayer(at: 0)
    self.nextButton.applyGradient()
  }

  fileprivate func setupUI() {
    self.setupPhotoDocumentView()
    self.setupPhotoDocumentBackView()
    self.setupPhotoHoldingDocumentView()
    self.setupNextButton()
    self.setupDocumentType()
  }

  fileprivate func setupDocumentType() {
    self.documentTypeTextLabel.text = NSLocalizedString("document.type", value: "Document Type", comment: "")
    self.documentTypeTextLabel.addLetterSpacing()
    self.documentNumberTextField.placeholder = NSLocalizedString("document.number", value: "Document Number", comment: "")
    self.documentNumberTextField.addPlaceholderSpacing()
    self.identityCardTextLabel.text = NSLocalizedString("identity.card", value: "Identity Card", comment: "")
    self.identityCardTextLabel.addLetterSpacing()
    self.passportTextLabel.text = NSLocalizedString("passport", value: "Passport", comment: "")
    self.passportTextLabel.addLetterSpacing()
    self.issueDateTextField.placeholder = NSLocalizedString("issue.date", value: "Issue Date", comment: "")
    self.issueDateTextField.addPlaceholderSpacing()
    self.expiryDateTextField.placeholder = NSLocalizedString("expiry.date", value: "Expiry Date", comment: "")
    self.expiryDateTextField.addPlaceholderSpacing()
    self.dontHaveIssueDateTextLabel.text = NSLocalizedString("none.applicable", value: "None applicable", comment: "")
    self.dontHaveIssueDateTextLabel.addLetterSpacing()
    self.dontHaveExpiryDateTextLabel.text = NSLocalizedString("none.applicable", value: "None applicable", comment: "")
    self.dontHaveExpiryDateTextLabel.addLetterSpacing()
    self.dontHaveIssueDateButton.rounded(color: UIColor.Kyber.border, width: 1.0, radius: 2.5)
    self.dontHaveExpiryDateButton.rounded(color: UIColor.Kyber.border, width: 1.0, radius: 2.5)
    self.issueDateTextField.inputView = self.issueDatePicker
    self.issueDateTextField.delegate = self
    self.expiryDateTextField.inputView = self.expiryDatePicker
    self.expiryDateTextField.delegate = self

    // Add gestures to labels
    let idTap = UITapGestureRecognizer(target: self, action: #selector(self.idButtonPressed(_:)))
    self.idTextLabel.isUserInteractionEnabled = true
    self.idTextLabel.addGestureRecognizer(idTap)

    let passportTap = UITapGestureRecognizer(target: self, action: #selector(self.passportButtonPressed(_:)))
    self.passportTextLabel.isUserInteractionEnabled = true
    self.passportTextLabel.addGestureRecognizer(passportTap)

    let dontHaveIssueTap = UITapGestureRecognizer(target: self, action: #selector(self.dontHaveIssueDataButtonPressed(_:)))
    self.dontHaveIssueDateTextLabel.isUserInteractionEnabled = true
    self.dontHaveIssueDateTextLabel.addGestureRecognizer(dontHaveIssueTap)

    let dontHaveExpiryTap = UITapGestureRecognizer(target: self, action: #selector(self.dontHaveExpiryDateButtonPressed(_:)))
    self.dontHaveExpiryDateTextLabel.isUserInteractionEnabled = true
    self.dontHaveExpiryDateTextLabel.addGestureRecognizer(dontHaveExpiryTap)

    self.updateDocumentTypeData()
  }

  fileprivate func setupPhotoDocumentView() {
    self.photoOfYourDocumentTextLabel.text = NSLocalizedString("photo.of.your.document.front", value: "Photo of your Document - Front", comment: "")
    self.photoOfYourDocumentTextLabel.addLetterSpacing()
    self.heightConstraintForDocumentPhotoView.constant = 180.0
    self.documentImageContainerView.isHidden = true
    self.documentImageContainerView.rounded(radius: 4.0)

    self.browseDocumentButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: KNAppStyleType.current.buttonRadius(for: self.browseDocumentButton.frame.height)
    )
    self.browseDocumentButton.setTitle(
      NSLocalizedString("browse", value: "Browse", comment: ""),
      for: .normal
    )
    self.browseDocumentButton.addTextSpacing()
  }

  fileprivate func setupPhotoDocumentBackView() {
    self.photoOfYourDocumentBackTextLabel.text = NSLocalizedString("photo.of.your.document.back", value: "Photo of your Document - Back", comment: "")
    self.photoOfYourDocumentBackTextLabel.addLetterSpacing()
    self.heightConstraintForDocumentPhotoBackView.constant = 180.0
    self.documentImageBackContainerView.isHidden = true
    self.documentImageBackContainerView.rounded(radius: 4.0)

    self.browserDocumentBackButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: KNAppStyleType.current.buttonRadius(for: self.browserDocumentBackButton.frame.height)
    )
    self.browserDocumentBackButton.addTextSpacing()
    self.browserDocumentBackButton.setTitle(
      NSLocalizedString("browse", value: "Browse", comment: ""),
      for: .normal
    )
  }

  fileprivate func setupPhotoHoldingDocumentView() {
    self.photoHoldingDocumentTextLabel.text = NSLocalizedString("photo.of.your.holding.document", value: "Photo of your holding Document", comment: "")
    self.photoHoldingDocumentTextLabel.addLetterSpacing()
    self.holdingDocumentImageContainerView.isHidden = true
    self.holdingDocumentImageContainerView.rounded(radius: 4.0)
    self.heightConstraintForHoldingDocumentPhotoView.constant = 48.0

    self.browseHoldingDocumentPhotoButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: KNAppStyleType.current.buttonRadius(for: self.browseHoldingDocumentPhotoButton.frame.height)
    )
    self.browseHoldingDocumentPhotoButton.setTitle(
      NSLocalizedString("browse", value: "Browse", comment: ""),
      for: .normal
    )
    self.browseHoldingDocumentPhotoButton.addTextSpacing()
  }

  fileprivate func setupNextButton() {
    self.nextButton.rounded(radius: KNAppStyleType.current.buttonRadius(for: self.nextButton.frame.height))
    self.nextButton.setTitle(NSLocalizedString("next", value: "Next", comment: ""), for: .normal)
    self.nextButton.addTextSpacing()
    self.nextButton.applyGradient()
  }

  fileprivate func updateDocumentTypeData() {
    self.idButton.rounded(
      color: self.viewModel.documentType == "national_id" ? UIColor.Kyber.enygold : UIColor.Kyber.border,
      width: self.viewModel.documentType == "national_id" ? 6.0 : 1.0,
      radius: self.idButton.frame.height / 2.0
    )
    self.passportButton.rounded(
      color: self.viewModel.documentType == "passport" ? UIColor.Kyber.enygold : UIColor.Kyber.border,
      width: self.viewModel.documentType == "passport" ? 6.0 : 1.0,
      radius: self.passportButton.frame.height / 2.0
    )
    self.updateDocumentBackView()
  }

  fileprivate func updateDocumentBackView() {
    let shouldHide = self.viewModel.documentType == "passport"
    self.photoBackContainerView.isHidden = shouldHide
    self.documentImageBackContainerView.isHidden = shouldHide || self.documentBackImage == nil
    self.topPaddingForPhotoHoldingDocumentConstraint.constant = shouldHide ? -self.heightConstraintForDocumentPhotoBackView.constant : 32.0
    self.view.layoutIfNeeded()
  }

  @objc func issueDatePickerDidChange(_ sender: Any) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dob = dateFormatter.string(from: self.issueDatePicker.date)
    self.issueDateTextField.text = dob
  }

  @objc func expiryDatePickerDidChange(_ sender: Any) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dob = dateFormatter.string(from: self.expiryDatePicker.date)
    self.expiryDateTextField.text = dob
  }

  @IBAction func idButtonPressed(_ sender: Any) {
    self.viewModel.updateDocumentType(self.viewModel.documentType == "national_id" ? "" : "national_id")
    self.updateDocumentTypeData()
  }

  @IBAction func passportButtonPressed(_ sender: Any) {
    self.viewModel.updateDocumentType(self.viewModel.documentType == "passport" ? "" : "passport")
    self.updateDocumentTypeData()
  }

  @IBAction func dontHaveIssueDataButtonPressed(_ sender: Any) {
    self.viewModel.updateHasIssueDate(has: !self.viewModel.hasIssueDate)
    self.updateDontHaveIssueDateButton()
  }

  fileprivate func updateDontHaveIssueDateButton() {
    self.dontHaveIssueDateButton.setImage(self.viewModel.dontHaveIssueDateImage, for: .normal)
    self.dontHaveIssueDateButton.rounded(color: self.viewModel.dontHaveIssueDateButtonBorder, width: 1.0, radius: 2.5)
    if self.viewModel.hasIssueDate {
      self.issueDateTextField.isEnabled = true
    } else {
      self.issueDateTextField.isEnabled = false
      self.issueDateTextField.text = ""
    }
    self.view.layoutIfNeeded()
  }

  @IBAction func dontHaveExpiryDateButtonPressed(_ sender: Any) {
    self.viewModel.updateHasExpiryDate(has: !self.viewModel.hasExpiryDate)
    self.updateDontHaveExpiryDateButton()
  }

  fileprivate func updateDontHaveExpiryDateButton() {
    self.dontHaveExpiryDateButton.setImage(self.viewModel.dontHaveExpiryDateImage, for: .normal)
    self.dontHaveExpiryDateButton.rounded(color: self.viewModel.dontHaveExpiryDateButtonBorder, width: 1.0, radius: 2.5)
    if self.viewModel.hasExpiryDate {
      self.expiryDateTextField.isEnabled = true
    } else {
      self.expiryDateTextField.isEnabled = false
      self.expiryDateTextField.text = ""
    }
    self.view.layoutIfNeeded()
  }

  @IBAction func photoOfYourDocumentInfoButtonPressed(_ sender: Any) {
    let documentTipsVC = KNDocumentPhotoInfoPopUp()
    documentTipsVC.modalPresentationStyle = .overFullScreen
    documentTipsVC.modalTransitionStyle = .crossDissolve
    self.present(documentTipsVC, animated: true, completion: nil)
  }

  @IBAction func browseDocumentPhotoButtonPressed(_ sender: Any) {
    self.pickingDocumentType = 0
    self.openImagePickerController()
  }

  @IBAction func photoHoldingDocumentInfoButtonPressed(_ sender: Any) {
    let holdingDocumentTipsVC = KNHoldingDocumentInfoPopUp()
    holdingDocumentTipsVC.modalPresentationStyle = .overFullScreen
    holdingDocumentTipsVC.modalTransitionStyle = .crossDissolve
    self.present(holdingDocumentTipsVC, animated: true, completion: nil)
  }

  @IBAction func browserDocumentBackButtonPressed(_ sender: Any) {
    self.pickingDocumentType = 1
    self.openImagePickerController()
  }

  @IBAction func browseHoldingDocumentPhotoButtonPressed(_ sender: Any) {
    self.pickingDocumentType = 2
    self.openImagePickerController()
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    guard !self.viewModel.documentType.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.document.type", value: "Invalid document type", comment: ""),
        message: NSLocalizedString("please.select.a.document.type", value: "Please select a document type", comment: ""),
        time: 1.5
      )
      return
    }
    let documentNumber = self.documentNumberTextField.text ?? ""
    guard !documentNumber.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.document.number", value: "Invalid document number", comment: ""),
        message: NSLocalizedString("please.enter.your.document.number", value: "Please enter your document number", comment: ""),
        time: 1.5
      )
      return
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let nowString = dateFormatter.string(from: Date())
    let issueDate = self.viewModel.hasIssueDate ? (self.issueDateTextField.text ?? "") : ""
    if self.viewModel.hasIssueDate && issueDate.isEmpty {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid Input", comment: ""),
        message: NSLocalizedString("please.provide.a.valid.issue.date", value: "Please provide a valid issue date", comment: ""),
        time: 2.5
      )
      return
    }
    if self.viewModel.hasIssueDate && issueDate > nowString {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid Input", comment: ""),
        message: NSLocalizedString("issue.date.can.not.be.in.the.future", value: "Issue date can not be in the future", comment: ""),
        time: 2.5
      )
      return
    }
    let expiryDate = self.viewModel.hasExpiryDate ? (self.expiryDateTextField.text ?? "") : ""
    if self.viewModel.hasExpiryDate && expiryDate.isEmpty {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid Input", comment: ""),
        message: NSLocalizedString("please.provide.a.valid.expiry.date", value: "Please provide a valid expiry date", comment: ""),
        time: 2.5
      )
      return
    }
    if self.viewModel.hasExpiryDate && expiryDate < nowString {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid Input", comment: ""),
        message: NSLocalizedString("expiry.date.can.not.be.in.the.past", value: "Expiry date can not be in the past", comment: ""),
        time: 2.5
      )
      return
    }
    guard let docFrontImage = self.documentFrontImage else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("photo.not.found", value: "Photo not found", comment: ""),
        message: NSLocalizedString("please.provide.your.document.photo", value: "Please provide your document photo for verification", comment: ""),
        time: 2.5
      )
      return
    }
    let docBackImage = self.viewModel.documentType != "passport" ? self.documentBackImage : nil
    if self.viewModel.documentType != "passport" {
      guard self.documentBackImage != nil else {
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("photo.not.found", value: "Photo not found", comment: ""),
          message: NSLocalizedString("please.provide.your.document.photo", value: "Please provide your document photo for verification", comment: ""),
          time: 2.5
        )
        return
      }
    }
    guard let docHoldingImage = self.holdingDocumentImage else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("photo.not.found", value: "Photo not found", comment: ""),
        message: NSLocalizedString("please.provide.a.photo.of.you.holding.your.document", value: "Please provide your document photo for verification", comment: ""),
        time: 2.5
      )
      return
    }
    let nextEvent = KYCIdentityInfoViewEvent.next(
      docType: self.viewModel.documentType,
      docNum: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      docFrontImage: docFrontImage,
      docBackImage: docBackImage,
      docHoldingImage: docHoldingImage
    )
    self.delegate?.identityInfoViewController(self, run: nextEvent)
  }

  fileprivate func openImagePickerController() {
    let alertController = UIAlertController(
      title: NSLocalizedString("choose.method", value: "Choose Method", comment: ""),
      message: NSLocalizedString("where.do.you.want.to.get.your.image", value: "Where do you want to get your image?", comment: ""),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("camera", value: "Camera", comment: ""), style: .default, handler: { _ in
      self.openImagePickerCamera()
    }))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("photo.library", value: "Photo Library", comment: ""), style: .default, handler: { _ in
      self.openImagePickerPhotoLibrary()
    }))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .destructive, handler: nil))
    self.present(alertController, animated: true, completion: nil)
  }

  fileprivate func openImagePickerCamera() {
    self.imagePicker = UIImagePickerController()
    self.imagePicker.mediaTypes = [kUTTypeImage as String]
    self.imagePicker.sourceType = .camera
    self.imagePicker.cameraFlashMode = .off
    self.imagePicker.videoQuality = .typeHigh
    self.imagePicker.delegate = self
    self.navigationController?.present(self.imagePicker, animated: true, completion: nil)
  }

  fileprivate func openImagePickerPhotoLibrary() {
    self.imagePicker.mediaTypes = [kUTTypeImage as String]
    self.imagePicker.sourceType = .photoLibrary
    self.imagePicker.delegate = self
    self.navigationController?.present(self.imagePicker, animated: true, completion: nil)
  }

  func updateIdentityInfo(with details: UserKYCDetailsInfo) {
    guard !details.documentType.isEmpty else { return }
    self.viewModel.updateDocumentType(details.documentType)
    self.updateDocumentTypeData()

    self.documentNumberTextField.text = details.documentNumber
    self.issueDateTextField.text = details.documentIssueDate
    self.viewModel.updateHasIssueDate(has: !details.documentIssueDate.isEmpty)
    self.updateDontHaveIssueDateButton()
    self.expiryDateTextField.text = details.documentExpiryDate
    self.viewModel.updateHasExpiryDate(has: !details.documentExpiryDate.isEmpty)
    self.updateDontHaveExpiryDateButton()

    let base64Prefix = "data:image/jpeg;base64,"
    if details.documentPhotoFront.starts(with: base64Prefix),
      let data = Data(base64Encoded: details.documentPhotoFront.substring(from: base64Prefix.count)),
      let image = UIImage(data: data) {
      self.updateDocumentPhotoFront(with: image, animate: false)
    }
    if details.documentPhotoBack.starts(with: base64Prefix),
      let data = Data(base64Encoded: details.documentPhotoBack.substring(from: base64Prefix.count)),
      let image = UIImage(data: data) {
      self.updateDocumentPhotoBack(with: image, animate: false)
    }
    if details.documentSelfiePhoto.starts(with: base64Prefix), let data = Data(base64Encoded: details.documentSelfiePhoto.substring(from: base64Prefix.count)), let image = UIImage(data: data) {
      self.updateHoldingDocumentPhoto(with: image, animate: false)
    }
    self.view.layoutIfNeeded()
  }

  fileprivate func updateDocumentPhotoFront(with image: UIImage, animate: Bool) {
    if animate { self.displayLoading() }
    DispatchQueue.global().async {
      self.documentFrontImage = image.compress(to: 0.75)
      DispatchQueue.main.async {
        if animate { self.hideLoading() }
        let width = self.documentImageContainerView.frame.width - 48.0
        let height = image.size.height / image.size.width * width
        let newImage = image.resizeImage(to: CGSize(width: width, height: height))
        self.heightConstraintForDocumentPhotoView.constant = 180.0 + height + 24.0 * 2.0 // image height + top/bottom padding
        self.documentImageView.image = newImage
        self.documentImageContainerView.isHidden = false
        self.view.layoutIfNeeded()
      }
    }
  }

  fileprivate func updateDocumentPhotoBack(with image: UIImage, animate: Bool) {
    if animate { self.displayLoading() }
    DispatchQueue.global().async {
      self.documentBackImage = image.compress(to: 0.75)
      DispatchQueue.main.async {
        if animate { self.hideLoading() }
        let width = self.documentImageContainerView.frame.width - 48.0
        let height = image.size.height / image.size.width * width
        let newImage = image.resizeImage(to: CGSize(width: width, height: height))
        self.heightConstraintForDocumentPhotoBackView.constant = 180.0 + height + 24.0 * 2.0 // image height + top/bottom padding
        self.documentBackImageView.image = newImage
        self.documentImageBackContainerView.isHidden = false
        self.view.layoutIfNeeded()
      }
    }
  }

  fileprivate func updateHoldingDocumentPhoto(with image: UIImage, animate: Bool) {
    if animate { self.displayLoading() }
    DispatchQueue.global().async {
      self.holdingDocumentImage = image.compress(to: 0.75)
      DispatchQueue.main.async {
        if animate { self.hideLoading() }
        let width = self.documentImageContainerView.frame.width - 48.0
        let height = image.size.height / image.size.width * width
        let newImage = image.resizeImage(to: CGSize(width: width, height: height))
        self.heightConstraintForHoldingDocumentPhotoView.constant = height + 24.0 * 2.0 // image height + top/bottom padding
        self.holdingDocumentImageView.image = newImage
        self.holdingDocumentImageContainerView.isHidden = false
        self.view.layoutIfNeeded()
      }
    }
  }
}
extension KYCIdentityInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
    picker.dismiss(animated: true) {
      guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
        return
      }
      if self.pickingDocumentType == 0 {
        self.updateDocumentPhotoFront(with: image, animate: true)
      } else if self.pickingDocumentType == 1 {
        self.updateDocumentPhotoBack(with: image, animate: true)
      } else {
        self.updateHoldingDocumentPhoto(with: image, animate: true)
      }
      self.view.layoutIfNeeded()
    }
  }
}

extension KYCIdentityInfoViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    let isDatePickerIssueDate = textField == self.issueDateTextField
    let date: Date = {
      if let text = textField.text {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: text) ?? Date()
      }
      return Date()
    }()
    if isDatePickerIssueDate {
      self.issueDatePicker.setDate(date, animated: false)
      self.issueDatePickerDidChange(textField)
    } else {
      self.expiryDatePicker.setDate(date, animated: false)
      self.expiryDatePickerDidChange(textField)
    }
  }
}
