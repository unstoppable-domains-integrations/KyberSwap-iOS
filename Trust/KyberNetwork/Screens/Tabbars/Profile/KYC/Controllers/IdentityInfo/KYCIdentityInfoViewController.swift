// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Photos
import MobileCoreServices
import AVFoundation

enum KYCIdentityInfoViewEvent {
  case next(docType: String, docNum: String, docImage: UIImage, docHoldingImage: UIImage)
}

protocol KYCIdentityInfoViewControllerDelegate: class {
  func identityInfoViewController(_ controller: KYCIdentityInfoViewController, run event: KYCIdentityInfoViewEvent)
}

class KYCIdentityInfoViewModel {

  fileprivate(set) var documentType: String = ""

  func updateDocumentType(_ type: String) { self.documentType = type }
}

class KYCIdentityInfoViewController: KNBaseViewController {

  @IBOutlet weak var documentTypeTextLabel: UILabel!
  @IBOutlet weak var idButton: UIButton!
  @IBOutlet weak var passportButton: UIButton!
  @IBOutlet weak var driverLicenseButton: UIButton!
  @IBOutlet weak var documentNumberTextField: UITextField!

  fileprivate var documentImage: UIImage?
  @IBOutlet weak var browseDocumentButton: UIButton!
  @IBOutlet weak var documentImageContainerView: UIView!
  @IBOutlet weak var documentImageView: UIImageView!
  @IBOutlet weak var heightConstraintForDocumentPhotoView: NSLayoutConstraint!

  fileprivate var holdingDocumentImage: UIImage?
  @IBOutlet weak var browseHoldingDocumentPhotoButton: UIButton!
  @IBOutlet weak var holdingDocumentImageContainerView: UIView!
  @IBOutlet weak var holdingDocumentImageView: UIImageView!
  @IBOutlet weak var heightConstraintForHoldingDocumentPhotoView: NSLayoutConstraint!

  @IBOutlet weak var nextButton: UIButton!

  weak var delegate: KYCIdentityInfoViewControllerDelegate?
  fileprivate let viewModel: KYCIdentityInfoViewModel

  fileprivate var isPickingDocumentPhoto: Bool = true
  fileprivate var imagePicker: UIImagePickerController = UIImagePickerController()

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

  fileprivate func setupUI() {
    self.setupDocumentType()
    self.setupPhotoDocumentView()
    self.setupPhotoHoldingDocumentView()
    self.setupNextButton()
  }

  fileprivate func setupDocumentType() {
    self.updateDocumentTypeData()
  }

  fileprivate func setupPhotoDocumentView() {
    self.heightConstraintForDocumentPhotoView.constant = 180.0
    self.documentImageContainerView.isHidden = true
    self.documentImageContainerView.rounded(radius: 4.0)

    self.browseDocumentButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
  }

  fileprivate func setupPhotoHoldingDocumentView() {
    self.holdingDocumentImageContainerView.isHidden = true
    self.holdingDocumentImageContainerView.rounded(radius: 4.0)

    self.browseHoldingDocumentPhotoButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
  }

  fileprivate func setupNextButton() {
    self.nextButton.rounded(radius: 4.0)
    self.nextButton.setTitle("Next".toBeLocalised(), for: .normal)
  }

  fileprivate func updateDocumentTypeData() {
    self.idButton.rounded(
      color: self.viewModel.documentType == "national_id" ? UIColor.Kyber.shamrock : UIColor.Kyber.border,
      width: self.viewModel.documentType == "national_id" ? 6.0 : 1.0,
      radius: self.idButton.frame.height / 2.0
    )
    self.passportButton.rounded(
      color: self.viewModel.documentType == "passport" ? UIColor.Kyber.shamrock : UIColor.Kyber.border,
      width: self.viewModel.documentType == "passport" ? 6.0 : 1.0,
      radius: self.passportButton.frame.height / 2.0
    )
    self.driverLicenseButton.rounded(
      color: self.viewModel.documentType == "driving_license" ? UIColor.Kyber.shamrock : UIColor.Kyber.border,
      width: self.viewModel.documentType == "driving_license" ? 6.0 : 1.0,
      radius: self.driverLicenseButton.frame.height / 2.0
    )
  }

  @IBAction func idButtonPressed(_ sender: Any) {
    self.viewModel.updateDocumentType(self.viewModel.documentType == "national_id" ? "" : "national_id")
    self.updateDocumentTypeData()
  }

  @IBAction func passportButtonPressed(_ sender: Any) {
    self.viewModel.updateDocumentType(self.viewModel.documentType == "passport" ? "" : "passport")
    self.updateDocumentTypeData()
  }

  @IBAction func driverLicenseButtonPressed(_ sender: Any) {
    self.viewModel.updateDocumentType(self.viewModel.documentType == "driving_license" ? "" : "driving_license")
    self.updateDocumentTypeData()
  }

  @IBAction func photoOfYourDocumentInfoButtonPressed(_ sender: Any) {
    //TODO: Show info
  }

  @IBAction func browseDocumentPhotoButtonPressed(_ sender: Any) {
    self.isPickingDocumentPhoto = true
    self.openImagePickerController()
  }

  @IBAction func photoHoldingDocumentInfoButtonPressed(_ sender: Any) {
    //TODO: Show info
  }

  @IBAction func browseHoldingDocumentPhotoButtonPressed(_ sender: Any) {
    self.isPickingDocumentPhoto = false
    self.openImagePickerController()
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    guard !self.viewModel.documentType.isEmpty else {
      self.showWarningTopBannerMessage(
        with: "Invalid document type".toBeLocalised(),
        message: "Please select a document type".toBeLocalised(),
        time: 1.5
      )
      return
    }
    let documentNumber = self.documentNumberTextField.text ?? ""
    guard !documentNumber.isEmpty else {
      self.showWarningTopBannerMessage(
        with: "Invalid document number".toBeLocalised(),
        message: "Please enter your document number".toBeLocalised(),
        time: 1.5
      )
      return
    }
    guard let docImage = self.documentImage else {
      self.showWarningTopBannerMessage(
        with: "Photo not found".toBeLocalised(),
        message: "Please provide your document photo for verification".toBeLocalised(),
        time: 2.5
      )
      return
    }
    guard let docHoldingImage = self.holdingDocumentImage else {
      self.showWarningTopBannerMessage(
        with: "Photo not found".toBeLocalised(),
        message: "Please provide a photo of you holding your document for verification".toBeLocalised(),
        time: 2.5
      )
      return
    }
    let nextEvent = KYCIdentityInfoViewEvent.next(
      docType: self.viewModel.documentType,
      docNum: documentNumber,
      docImage: docImage,
      docHoldingImage: docHoldingImage
    )
    self.delegate?.identityInfoViewController(self, run: nextEvent)
  }

  fileprivate func openImagePickerController() {
    let alertController = UIAlertController(
      title: "Choose Method",
      message: "Where do you want to get your image?",
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
      self.openImagePickerCamera()
    }))
    alertController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
      self.openImagePickerPhotoLibrary()
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
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
      let width = self.documentImageContainerView.frame.width - 48.0
      let height = image.size.height / image.size.width * width
      let newImage = image.resizeImage(to: CGSize(width: width, height: height))
      if self.isPickingDocumentPhoto {
        // maximum 1Mb
        self.documentImage = image.compress(to: 0.99)
        self.heightConstraintForDocumentPhotoView.constant = 180.0 + height + 24.0 * 2.0 // image height + top/bottom padding
        self.documentImageView.image = newImage
        self.documentImageContainerView.isHidden = false
        self.view.layoutIfNeeded()
      } else {
        // maximum 1Mb
        self.holdingDocumentImage = image.compress(to: 0.99)
        self.heightConstraintForHoldingDocumentPhotoView.constant = height + 24.0 * 2.0 // image height + top/bottom padding
        self.holdingDocumentImageView.image = newImage
        self.holdingDocumentImageContainerView.isHidden = false
        self.view.layoutIfNeeded()
      }
    }
  }
}
