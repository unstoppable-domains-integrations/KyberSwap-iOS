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
  let residenceCountry: String
  let docType: String
  let docNum: String
  let docImage: UIImage?
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

    self.updateViewModel(self.viewModel)
  }

  func updateViewModel(_ viewModel: KYCSubmitInfoViewModel) {
    self.viewModel = viewModel

    self.fullNameLabel.text = self.viewModel.firstName + " " + self.viewModel.lastName
    self.genderLabel.text = self.viewModel.gender
    self.dobLabel.text = self.viewModel.dob
    self.nationalityLabel.text = self.viewModel.nationality
    self.residenceCountryLabel.text = self.viewModel.residenceCountry
    self.documentTypeLabel.text = self.viewModel.docType
    self.documentNumberLabel.text = self.viewModel.docNum

    if let image = self.viewModel.docImage {
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

  func updateSubmitInfo(with details: IEOUserKYCDetails) {
    let base64Prefix = "data:image/jpeg;base64,"
    let docImage: UIImage? = {
      if details.documentPhoto.starts(with: base64Prefix),
        let data = Data(base64Encoded: details.documentPhoto.substring(from: base64Prefix.count)),
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
    let viewModel = KYCSubmitInfoViewModel(
      firstName: details.firstName,
      lastName: details.lastName,
      gender: details.gender ? "Male" : "Female",
      dob: details.dob,
      nationality: details.nationality,
      residenceCountry: details.country,
      docType: details.documentType,
      docNum: details.documentNumber,
      docImage: docImage,
      docHoldingImage: docHoldingImage
    )
    self.updateViewModel(viewModel)
  }
}
