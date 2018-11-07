// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KYCSubmitInfoViewEvent {
  case submit
}

protocol KYCSubmitInfoViewControllerDelegate: class {
  func submitInfoViewController(_ controller: KYCSubmitInfoViewController, run event: KYCSubmitInfoViewEvent)
}

struct KYCSubmitInfoViewModel {
  let firstName: String
  let lastName: String
  let gender: String
  let dob: String
  let nationality: String
  let residenceAddress: String
  let country: String
  let city: String
  let zipCode: String
  let proofAddress: String
  let proofAddressImage: UIImage?
  let sourceFund: String
  let occupationCode: String?
  let industryCode: String?
  let taxResidencyCountry: String?
  let taxIDNumber: String?
  let docType: String
  let docNum: String
  let issueDate: String
  let expiryDate: String
  let docFrontImage: UIImage?
  let docBackImage: UIImage?
  let docHoldingImage: UIImage?
}

class KYCSubmitInfoViewController: KNBaseViewController {

  fileprivate var viewModel: KYCSubmitInfoViewModel
  weak var delegate: KYCSubmitInfoViewControllerDelegate?

  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var genderLabel: UILabel!
  @IBOutlet weak var dobLabel: UILabel!
  @IBOutlet weak var nationalityLabel: UILabel!
  @IBOutlet weak var residenceCountryLabel: UILabel!
  @IBOutlet weak var documentTypeLabel: UILabel!
  @IBOutlet weak var documentNumberLabel: UILabel!

  @IBOutlet weak var documentImageView: UIImageView!
  @IBOutlet weak var documentPhotoContainerView: UIView!

  @IBOutlet weak var holdingDocumentPhotoContainerView: UIView!
  @IBOutlet weak var holdingDocumentImageView: UIImageView!

  @IBOutlet weak var submitButton: UIButton!

  @IBOutlet weak var personalInfoTextLabel: UILabel!
  @IBOutlet weak var fullNameTextLabel: UILabel!
  @IBOutlet weak var genderTextLabel: UILabel!
  @IBOutlet weak var dateOfBirthTextLabel: UILabel!
  @IBOutlet weak var nationalityTextLabel: UILabel!
  @IBOutlet weak var countryResidenceTextLabel: UILabel!
  @IBOutlet weak var idPassportTextLabel: UILabel!
  @IBOutlet weak var documentTypeTextLabel: UILabel!
  @IBOutlet weak var documentNumberTextLabel: UILabel!
  @IBOutlet weak var photoOfDocumentTextLabel: UILabel!
  @IBOutlet weak var photoHoldingDocumentTextLabel: UILabel!

  init(viewModel: KYCSubmitInfoViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KYCSubmitInfoViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.documentPhotoContainerView.rounded(radius: 4.0)
    self.holdingDocumentPhotoContainerView.rounded(radius: 4.0)

    self.submitButton.rounded(radius: 4.0)

    self.personalInfoTextLabel.text = NSLocalizedString("personal.info", value: "Personal Info", comment: "")
    self.fullNameTextLabel.text = NSLocalizedString("full.name", value: "Full Name", comment: "")
    self.genderTextLabel.text = NSLocalizedString("gender", value: "Gender", comment: "")
    self.dateOfBirthTextLabel.text = "\(NSLocalizedString("date.of.birth", value: "Date of birth", comment: "")) (YYYY-MM-DD)"
    self.nationalityTextLabel.text = NSLocalizedString("nationality", value: "Nationality", comment: "")
    self.countryResidenceTextLabel.text = NSLocalizedString("country.of.residence", value: "Country of Residence", comment: "")
    self.idPassportTextLabel.text = NSLocalizedString("id.passport", value: "ID/ Passport", comment: "")
    self.documentTypeTextLabel.text = NSLocalizedString("document.type", value: "Document Type", comment: "")
    self.documentNumberTextLabel.text = NSLocalizedString("document.number", value: "Document Number", comment: "")
    self.photoOfDocumentTextLabel.text = NSLocalizedString("photo.of.your.document", value: "Photo of your Document", comment: "")
    self.photoHoldingDocumentTextLabel.text = NSLocalizedString("photo.of.your.holding.document", value: "Photo of your holding Document", comment: "")
    self.submitButton.setTitle(
      NSLocalizedString("submit", value: "Submit", comment: ""),
      for: .normal
    )
    self.updateViewModel(self.viewModel)
  }

  func updateViewModel(_ viewModel: KYCSubmitInfoViewModel) {
    self.viewModel = viewModel

    self.fullNameLabel.text = self.viewModel.firstName + " " + self.viewModel.lastName
    self.genderLabel.text = self.viewModel.gender
    self.dobLabel.text = self.viewModel.dob
    self.nationalityLabel.text = self.viewModel.nationality
    self.residenceCountryLabel.text = self.viewModel.country
    self.documentTypeLabel.text = self.viewModel.docType
    self.documentNumberLabel.text = self.viewModel.docNum

    if let image = self.viewModel.docFrontImage {
      let width = self.documentPhotoContainerView.frame.width - 48.0
      let height = image.size.height / image.size.width * width
      let newImage = image.resizeImage(to: CGSize(width: width, height: height))
      self.documentImageView.image = newImage
    }

    if let image = self.viewModel.docHoldingImage {
      let width = self.holdingDocumentPhotoContainerView.frame.width - 48.0
      let height = image.size.height / image.size.width * width
      let newImage = image.resizeImage(to: CGSize(width: width, height: height))
      self.holdingDocumentImageView.image = newImage
    }
  }

  @IBAction func submitButonPressed(_ sender: Any) {
    self.delegate?.submitInfoViewController(self, run: .submit)
  }

  func updateSubmitInfo(with details: IEOUserKYCDetails2) {
    let base64Prefix = "data:image/jpeg;base64,"
    let docFrontImage: UIImage? = {
      if details.documentPhotoFront.starts(with: base64Prefix),
        let data = Data(base64Encoded: details.documentPhotoFront.substring(from: base64Prefix.count)),
        let image = UIImage(data: data) {
        return image
      }
      return nil
    }()
    let docBackImage: UIImage? = {
      if details.documentPhotoBack.starts(with: base64Prefix),
        let data = Data(base64Encoded: details.documentPhotoBack.substring(from: base64Prefix.count)),
        let image = UIImage(data: data) {
        return image
      }
      return nil
    }()
    let docHoldingImage: UIImage? = {
      if details.documentSelfiePhoto.starts(with: base64Prefix), let data = Data(base64Encoded: details.documentSelfiePhoto.substring(from: base64Prefix.count)), let image = UIImage(data: data) {
        return image
      }
      return nil
    }()
    let proofAddress: UIImage? = {
      if details.photoProofAddress.starts(with: base64Prefix), let data = Data(base64Encoded: details.photoProofAddress.substring(from: base64Prefix.count)), let image = UIImage(data: data) {
        return image
      }
      return nil
    }()
    let docType: String = {
      if details.documentType == "national_id" { return "ID" }
      if details.documentType == "passport" {
        return NSLocalizedString("passport", value: "Passport", comment: "")
      }
      if details.documentType == "driving_license" {
        return NSLocalizedString("driving.license", value: "Driving License", comment: "")
      }
      return details.documentType
    }()
    let viewModel = KYCSubmitInfoViewModel(
      firstName: details.firstName,
      lastName: details.lastName,
      gender: details.gender ? NSLocalizedString("male", value: "Male", comment: "") : NSLocalizedString("female", value: "Female", comment: ""),
      dob: details.dob,
      nationality: details.nationality,
      residenceAddress: details.residentialAddress,
      country: details.country,
      city: details.city,
      zipCode: details.zipCode,
      proofAddress: details.documentProofAddress,
      proofAddressImage: proofAddress,
      sourceFund: details.sourceFund,
      occupationCode: details.occupationCode,
      industryCode: details.industryCode,
      taxResidencyCountry: details.taxResidencyCountry,
      taxIDNumber: details.taxIDNUmber,
      docType: docType,
      docNum: details.documentNumber,
      issueDate: details.documentIssueDate,
      expiryDate: details.documentExpiryDate,
      docFrontImage: docFrontImage,
      docBackImage: docBackImage,
      docHoldingImage: docHoldingImage
    )
    self.updateViewModel(viewModel)
  }
}
